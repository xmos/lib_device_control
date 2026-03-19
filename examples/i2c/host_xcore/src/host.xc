// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <platform.h>
#include <stdio.h>
#include <stdlib.h>
#include <syscall.h>
#include <assert.h>
#include <timer.h>

#include "i2c.h"
#include "control_host.h"
#include "resource.h"
#include "control_host_util.h"

#define INVALID_VERSION 0xFF

// Payload size can be from 1 to 253 bytes
#define PAYLOAD_SIZE 1

port p_scl = on tile[0]: XS1_PORT_1N; // Can be accessed via signal SCL_3V3, TP13
port p_sda = on tile[0]: XS1_PORT_1O; // Can be accessed via signal SDA_3V3, TP14

int main(void)
{
  i2c_master_if i_i2c[1];
  par {
    on tile[0]: {
      i2c_master(i_i2c, 1, p_scl, p_sda, 100);
    }
    on tile[1]: {
      control_version_t version = INVALID_VERSION;
      unsigned char payload[PAYLOAD_SIZE];

      if (control_init_i2c(DEVICE_I2C_ADDRESS) != CONTROL_SUCCESS) {
        printf("control init failed\n");
        exit(1);
      }

      printf("i2c ready\n");

      if (control_query_version(&version, i_i2c[0]) != CONTROL_SUCCESS) {
        printf("control query version failed\n");
        exit(1);
      }
      if (version != CONTROL_VERSION) {
        printf("version expected 0x%X, received 0x%X\n", CONTROL_VERSION, version);
      }

      printf("started\n");
      for (uint8_t i = 0; i < sizeof(payload); i++) {
        payload[i] = (uint8_t)(i + 1);
      }


      for (uint8_t i = 0; i < 4; i++) {
        payload[0] = i;
        if (control_write_command(RESOURCE_ID, CONTROL_CMD_SET_WRITE(0), i_i2c[0], payload, sizeof(payload)) != CONTROL_SUCCESS) {
          printf("control write command failed\n");
          exit(1);
        }

        pause_short();

        if (control_read_command(RESOURCE_ID, CONTROL_CMD_SET_READ(0), i_i2c[0], payload, sizeof(payload)) != CONTROL_SUCCESS) {
          printf("control read command failed\n");
          exit(1);
        }

        pause_long();

        if (payload[0] != i) {
          printf("control read command returned the wrong value, expected %d, returned %d\n", i, payload[0]);
          exit(1);
        }
        printf("Written and read back command with payload: 0x%02X\n", payload[0]);
      }

      control_cleanup_i2c();
      printf("done\n");
      exit(0);
    }
  }
  return 0;
}