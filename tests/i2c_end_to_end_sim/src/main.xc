// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <platform.h>
#include <stdio.h>
#include <syscall.h>
#include "i2c.h"
#include "control.h"
#include "resource.h"
#include "app_host.h"
#include "app_device.h"


on tile[0]: port p_scl_host = XS1_PORT_1A;
on tile[0]: port p_sda_host = XS1_PORT_1B;

on tile[1]: port p_scl_device = XS1_PORT_1A;
on tile[1]: port p_sda_device = XS1_PORT_1B;

const char i2c_device_addr = I2C_ADDR;

int main(void)
{
  i2c_master_if i_i2c_host[1];

  i2c_slave_callback_if i_i2c_device;
  interface control i_control[1];

  par {
    /* Tile 0 contains the host test app */
    on tile[0]: par {
      host_app(i_i2c_host[0]);
      i2c_master(i_i2c_host, 1, p_scl_host, p_sda_host, 400);
    }

    /* Tile 1 contains the device test app*/
    on tile[1]: par {
      app_device(i_control[0]);
      i2c_client(i_i2c_device, i_control);
      i2c_slave(i_i2c_device, p_scl_device, p_sda_device, i2c_device_addr);
    }
  }
  return 0;
}
