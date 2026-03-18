// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <platform.h>
#include <stdio.h>
#include <syscall.h>
#include <timer.h>

#include "transport_i2c.h"
#include "i2c.h"
#include "control.h"
#include "app.h"
#include "resource.h"

on tile[PORT_I2C_SCL_TILE_NUM]: port p_scl = PORT_I2C_SCL;
on tile[PORT_I2C_SDA_TILE_NUM]: port p_sda = PORT_I2C_SDA;

int main(void)
{
  i2c_slave_callback_if i_i2c;
  interface control i_control[CONTROL_INTERFACES_NUM];

  par {
    on tile[PORT_I2C_SCL_TILE_NUM]: par {
      app(i_control[0]);
    }
    on tile[PORT_I2C_SCL_TILE_NUM]: {
      control_init();
      control_register_resources(i_control, CONTROL_INTERFACES_NUM);

      /* bug 17317 - [[combine]] */
      par {
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
        i2c_control_client(i_i2c, i_control);
#pragma warning enable
        i2c_slave(i_i2c, p_scl, p_sda, DEVICE_I2C_ADDRESS);
      }
    }
  }
  return 0;
}
