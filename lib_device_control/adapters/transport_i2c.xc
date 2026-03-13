// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "control.h"
#if CONTROL_USE_I2C

#include "transport_i2c.h"

#include <platform.h>

#include "i2c.h"

// I2C transport client processing function, this passes I2C data to the control interface.
//
// To include this file in the build, define CONTROL_USE_I2C as 1, in control_conf.h

[[distributable]]
void i2c_control_client(server i2c_slave_callback_if i_i2c, client interface control i_control[CONTROL_INTERFACES_NUM])
{
  while (1) {
    select {
      case i_i2c.ack_write_request(void) -> i2c_slave_ack_t resp:
        if (control_process_i2c_write_start(i_control) == CONTROL_SUCCESS)
          resp = I2C_SLAVE_ACK;
        else
          resp = I2C_SLAVE_NACK;
        break;

      case i_i2c.ack_read_request(void) -> i2c_slave_ack_t resp:
        if (control_process_i2c_read_start(i_control) == CONTROL_SUCCESS)
          resp = I2C_SLAVE_ACK;
        else
          resp = I2C_SLAVE_NACK;
        break;

      case i_i2c.master_sent_data(uint8_t data) -> i2c_slave_ack_t resp:
        if (control_process_i2c_write_data(data, i_control) == CONTROL_SUCCESS)
          resp = I2C_SLAVE_ACK;
        else {
          resp = I2C_SLAVE_NACK;
        }
        break;
      case i_i2c.master_requires_data(void) -> uint8_t data:
        control_process_i2c_read_data(data, i_control);
        break;
      case i_i2c.stop_bit(void):
        control_process_i2c_stop(i_control);
        break;

    }
  }
}

#endif // CONTROL_USE_I2C
