#include <platform.h>
#include <stdio.h>
#include <syscall.h>
#include <assert.h>
#include <timer.h>
#include "i2c.h"
#include "control.h"

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

/* TODO [[combinable]] */
void i2c_server(server i2c_slave_callback_if i_i2c, client interface control i_module[])
{
  uint8_t bytes[256];
  size_t num_bytes_write;
  size_t num_bytes_read;
  size_t return_size;
  int pending;
  timer tmr;
  int tmr_t;

  num_bytes_write = 0;
  num_bytes_read = 0;
  pending = 0;

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
	if (num_bytes_write < sizeof(bytes)) {
	  bytes[num_bytes_write] = data;
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
	if (num_bytes_read < return_size) {
	  data = bytes[num_bytes_read];
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
        control_handle_message_i2c(bytes, num_bytes_write, return_size, i_module, 1);
	pending = 0;
        break;
    }
  }
}

void app(server interface control i_module)
{
  unsigned num_commands;
  int i;

  printf("started\n");

  num_commands = 0;

  while (1) {
    select {
      case i_module.set(int address, size_t payload_size, const uint8_t payload[]):
        printf("%u: received SET: 0x%06x %d,", num_commands, address, payload_size);
        for (i = 0; i < payload_size; i++) {
          printf(" %02x", payload[i]);
        }
        printf("\n");
        num_commands++;
        break;

      case i_module.get(int address, size_t payload_size, uint8_t payload[]):
        assert(payload_size == 4);
        payload[0] = 0x12;
        payload[1] = 0x34;
        payload[2] = 0x56;
        payload[3] = 0x78;
        printf("%u: received GET: 0x%06x %d,", num_commands, address, payload_size);
        printf(" returned %d bytes", payload_size);
        printf("\n");
        num_commands++;
        break;
    }
  }
}

int main(void)
{
  i2c_slave_callback_if i_i2c;
  interface control i_module[1];
  par {
    on tile[0]: app(i_module[0]);
    on tile[0]: i2c_server(i_i2c, i_module);
    on tile[1]: {
      p_eth_phy_reset <: 0;
      i2c_slave(i_i2c, p_scl, p_sda, device_addr);
    }
  }
  return 0;
}
