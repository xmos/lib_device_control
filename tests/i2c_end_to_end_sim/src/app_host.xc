// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <platform.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "i2c.h"
#include "control_host.h"
#include "resource.h"
#include "app_host.h"

void host_app(client i2c_master_if i_i2c_host){
  control_version_t version;
  const unsigned char payload_write[4] = {0x99, 0xed};
  unsigned char payload[4];
  int i;
  //printf("Start host app\n");

  if (control_init_i2c(I2C_ADDR) != CONTROL_SUCCESS) {
    printf("ERROR - control init failed\n");
    _Exit(1);
  }

  printf("Device found\n");

  if (control_query_version(&version, i_i2c_host) != CONTROL_SUCCESS) {
    printf("ERROR - control query version failed\n");
    _Exit(1);
  }
  if (version != CONTROL_VERSION) {
    printf("version expected 0x%X, received 0x%X\n", CONTROL_VERSION, version);
  }

  printf("started\n");

  for (i = 0; i < 2; i++) {
    memcpy(payload, payload_write, sizeof(payload_write));
    if (control_write_command(RESOURCE_ID, CONTROL_CMD_SET_WRITE(0), i_i2c_host, payload, 2) != CONTROL_SUCCESS) {
      printf("ERROR - control write command failed\n");
      _Exit(1);
    }
    printf("Host written successfully\n");
    fflush(stdout);

    if (control_read_command(RESOURCE_ID, CONTROL_CMD_SET_READ(0), i_i2c_host, payload, 4) != CONTROL_SUCCESS) {
      printf("ERROR - control read command failed\n");
      _Exit(1);
    }
    printf("Host read successfully: 0x%x, 0x%x, 0x%x, 0x%x\n", payload[0], payload[1], payload[2], payload[3]);
    fflush(stdout);
  }
  control_cleanup_i2c();
  printf("Success!!\n");
  _Exit(0);
}
