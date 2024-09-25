// Copyright 2016-2024 XMOS LIMITED.
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
#include "util.h"

port p_scl = on tile[0]: XS1_PORT_1E; /* XE232 board J5 pin 13 */
port p_sda = on tile[0]: XS1_PORT_1F; /* J5 pin 14 */
                                      /* ground J5 pins 8 and 16 */
int main(void)
{
  i2c_master_if i_i2c[1];
  par {
    on tile[0]: i2c_master(i_i2c, 1, p_scl, p_sda, 200);
    on tile[1]: {
      control_version_t version;
      unsigned char payload[4];
      int i;

      if (control_init_i2c(123) != CONTROL_SUCCESS) {
        printf("control init failed\n");
        exit(1);
      }

      printf("device found\n");

      if (control_query_version(&version, i_i2c[0]) != CONTROL_SUCCESS) {
        printf("control query version failed\n");
        exit(1);
      }
      if (version != CONTROL_VERSION) {
        printf("version expected 0x%X, received 0x%X\n", CONTROL_VERSION, version);
      }

      printf("started\n");

      while (1) {
        for (i = 0; i < 4; i++) {
          payload[0] = 1;
          if (control_write_command(RESOURCE_ID, CONTROL_CMD_SET_WRITE(0), i_i2c[0], payload, 1) != CONTROL_SUCCESS) {
            printf("control write command failed\n");
            exit(1);
          }
          printf("W");
          fflush(stdout);

          pause_short();

          if (control_read_command(RESOURCE_ID, CONTROL_CMD_SET_READ(0), i_i2c[0], payload, 1) != CONTROL_SUCCESS) {
            printf("control read command failed\n");
            exit(1);
          }
          printf("R");
          fflush(stdout);

          pause_long();

          if (payload[0] != i) {
            printf("control read command returned the wrong value, expected %d, returned %d\n", i, payload[0]);
            exit(1);
          }
          printf("Written and read back command with payload: 0x%02X\n", payload[0]);
        }
      }

      control_cleanup_i2c();
    }
  }
  return 0;
}