// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <platform.h>
#include <stdio.h>
#include <syscall.h>
#include <timer.h>
#include "i2c.h"
#include "control.h"
#include "app.h"

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

const char i2c_device_addr = 123;

[[combinable]]
void i2c_client(server i2c_slave_callback_if i_i2c, client interface control i_control[1])
{
  /* I2C slave code based on app note AN00157, "How to use the I2C slave library" */
  unsigned regnum;

  regnum = -1;

  while (1) {
    select {
      case i_i2c.ack_write_request(void) -> i2c_slave_ack_t resp:
        /* always accept a write */
        resp = I2C_SLAVE_ACK;
        break;

      case i_i2c.ack_read_request(void) -> i2c_slave_ack_t resp:
        /* only accept a read if it follows a write to select register */
	if (regnum != -1) {
	  resp = I2C_SLAVE_NACK;
	}
	else {
	  resp = I2C_SLAVE_ACK;
	}
        break;

      case i_i2c.master_sent_data(uint8_t data) -> i2c_slave_ack_t resp:
        /* first write selects a register, further writes write to the selected register */
	if (regnum == -1) {
          regnum = data;
	  resp = I2C_SLAVE_ACK; /* was NACK in AN00157 */
	}
	else {
          control_process_i2c_write_transaction(regnum, data, i_control, 1);
          regnum = -1;
	  resp = I2C_SLAVE_ACK;
	}
        break;

      case i_i2c.master_requires_data(void) -> uint8_t data:
        /* register should be selected at this point */
	if (regnum != -1) {
          control_process_i2c_read_transaction(regnum, data, i_control, 1);
	}
	else {
	  data = 0;
	}
        break;

      /* no use for these callbacks, ignore them */
      case i_i2c.start_read_request(void): break;
      case i_i2c.start_write_request(void): break;
      case i_i2c.start_master_write(void): break;
      case i_i2c.start_master_read(void): break;
      case i_i2c.stop_bit(void): break;
    }
  }
}

int main(void)
{
  i2c_slave_callback_if i_i2c;
  interface control i_control[1];
  par {
    on tile[0]: app(i_control[0]);
    on tile[1]: {
      p_eth_phy_reset <: 0;
      /* bug 17317 - [[combine]] */
      par {
        i2c_client(i_i2c, i_control);
        i2c_slave(i_i2c, p_scl, p_sda, i2c_device_addr);
      }
    }
  }
  return 0;
}
