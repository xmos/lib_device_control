// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <platform.h>
#include <stdio.h>
#include <syscall.h>
#include <timer.h>
#include "i2c.h"
#include "control.h"
#include "app.h"

#ifndef I2C_TILE
#define I2C_TILE 1  // Vision Board: Tile 1, else: tile 0
#endif

on tile[I2C_TILE]: port p_scl = PORT_I2C_SCL;
on tile[I2C_TILE]: port p_sda = PORT_I2C_SDA;

const char i2c_device_addr = 0x2C;

void i2c_client(server i2c_slave_callback_if i_i2c, client interface control i_control[1])
{
  while (1) {
    select {
      case i_i2c.ack_write_request(void) -> i2c_slave_ack_t resp:
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
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
#pragma warning enable

    }
  }
}

int main(void)
{
  i2c_slave_callback_if i_i2c;
  interface control i_control[1];

  par {
    on tile[I2C_TILE]: par {
      app(i_control[0]);
      }
    on tile[I2C_TILE]: {
      control_init();
      control_register_resources(i_control, 1);

      /* bug 17317 - [[combine]] */
      par {
        i2c_client(i_i2c, i_control);
        i2c_slave(i_i2c, p_scl, p_sda, i2c_device_addr);
      }
    }
  }
  return 0;
}
