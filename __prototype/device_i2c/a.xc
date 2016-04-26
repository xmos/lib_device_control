#include <platform.h>
#include <stdio.h>
#include <syscall.h>
#include <assert.h>
#include <timer.h>
#include "i2c.h"

/* Microphone array board
 *
 * need to use 1bit ports for I2C, because I2C library slave is only 1bit port
 * I2C ports are on a 4bit port, so 1bit Ethernet ports instead:
 *
 *    SCL ETH_RXCLK X1D00 port 1A (resistor R60)
 *    SDA ETH_TXCLK X1D01 port 1B (resistor R57)
 *
 * also hold Ethernet PHY in reset to ensure it is not driving clock:
 *
 *    ETH_RST_N X1D29 port 4F bit 1
 */
port p_scl = on tile[1]: XS1_PORT_1A;
port p_sda = on tile[1]: XS1_PORT_1B;
out port p_eth_phy_reset = on tile[1]: XS1_PORT_4F;

const char device_addr = 123;

enum {
  COMMAND_GET = 1,
  COMMAND_SET = 2
};

struct command {
  uint8_t direction;
  uint8_t entity;
  uint8_t address[3]; /* big endian convention */
  uint8_t payload_length;
  uint8_t payload[64]; /* USB control request maximum, xSCOPE is probably 256 */
};

unsigned ntoh24(const unsigned char b[3])
{
  return ((unsigned)b[0] << 16) | ((unsigned)b[1] << 8) | (unsigned)b[0];
}

[[combinable]]
void i2c_server(server i2c_slave_callback_if i_i2c, chanend c_app)
{
  struct command c;
  unsigned char *cb;
  int num_bytes_write;
  int num_bytes_read;
  int pending;
  int i;
  timer tmr;
  int tmr_t;

  num_bytes_write = 0;
  num_bytes_read = 0;
  pending = 0;
  cb = (void*)&c;

  while (1) {
    select {
      case i_i2c.start_read_request(void):
        num_bytes_read = 0;
        break;
      case i_i2c.ack_read_request(void) -> i2c_slave_ack_t resp:
	if (pending) {
	  resp = I2C_SLAVE_NACK;
	}
	else {
	  resp = I2C_SLAVE_ACK;
	}
        break;
      case i_i2c.start_write_request(void):
        num_bytes_write = 0;
        break;
      case i_i2c.ack_write_request(void) -> i2c_slave_ack_t resp:
	if (pending) {
	  resp = I2C_SLAVE_NACK;
	}
	else {
	  resp = I2C_SLAVE_ACK;
	}
        break;
      case i_i2c.start_master_write(void):
        break;
      case i_i2c.master_sent_data(uint8_t data) -> i2c_slave_ack_t resp:
	if (num_bytes_write < sizeof(struct command)) {
	  cb[num_bytes_write] = data;
	  resp = I2C_SLAVE_ACK;
	}
	else {
	  resp = I2C_SLAVE_NACK;
	}
	num_bytes_write++;
        break;
      case i_i2c.start_master_read(void):
        break;
      case i_i2c.master_requires_data() -> uint8_t data:
	if (num_bytes_read < c.payload_length) {
	  data = c.payload[num_bytes_read];
	}
	num_bytes_read++;
        break;
      case i_i2c.stop_bit():
	if (num_bytes_read > 0) {
	  num_bytes_read = 0;
	}
	if (num_bytes_write > 0) {
	  num_bytes_write = 0;
	  pending = 1;
	  tmr :> tmr_t;
	}
	break;
      case pending => tmr when timerafter(tmr_t) :> void:
	c_app <: c.direction;
	master {
	  c_app <: ntoh24(c.address);
	  c_app <: c.payload_length;
	  if (c.direction == COMMAND_SET) {
	    for (i = 0; i < c.payload_length; i++) {
	      c_app <: c.payload[i];
	    }
	  }
	}
	if (c.direction == COMMAND_GET) {
	  slave {
	    for (i = 0; i < c.payload_length; i++) {
	      c_app :> c.payload[i];
	    }
	  }
	}
	pending = 0;
        break;
    }
  }
}

void app(chanend c_app)
{
  char direction;
  int address;
  char n;
  int i;
  unsigned char payload[8];
  unsigned num_commands;

  printf("started\n");
  printf("device address %d\n", device_addr);

  num_commands = 0;

  while (1) {
    select {
      case c_app :> direction:
        slave {
          c_app :> address;
          c_app :> n;
          if (direction == COMMAND_SET) {
            assert(n <= sizeof(payload));
            for (i = 0; i < n; i++) {
              c_app :> payload[i];
            }
          }
        }
        if (direction == COMMAND_GET) {
          master {
            assert(n == 4);
            c_app <: (char)0x12;
            c_app <: (char)0x34;
            c_app <: (char)0x56;
            c_app <: (char)0x78;
          }
        }
        printf("%u: received %s: 0x%06x %d,", num_commands, direction == COMMAND_GET ? "GET" : "SET", address, n);
        if (direction == COMMAND_SET) {
          for (i = 0; i < n; i++) {
            printf(" %02x", payload[i]);
          }
        }
        else {
          printf(" returned %d bytes", n);
        }
        printf("\n");
        num_commands++;
        break;
    }
  }
}

int main(void)
{
  i2c_slave_callback_if i_i2c;
  chan c_app;
  par {
    on tile[0]: app(c_app);
    on tile[0]: i2c_server(i_i2c, c_app);
    on tile[1]: {
      p_eth_phy_reset <: 0;
      i2c_slave(i_i2c, p_scl, p_sda, device_addr);
    }
  }
  return 0;
}
