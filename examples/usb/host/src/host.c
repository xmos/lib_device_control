// Copyright 2016-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdio.h>
#include <stdlib.h>
#include "control_host.h"
#include "util.h"
#include "resource.h"

#define INVALID_CONTROL_VERSION 0xFF

int main(void)
{
  control_version_t version = INVALID_CONTROL_VERSION;
  // Exercise the control interface by writing and reading commands
  // buffer is greater than 64 bytes to test USB control packet handling
  uint8_t payload[100];

  if (control_init_usb(0x20B1, 0x001A, 0) != CONTROL_SUCCESS) {
    printf("control init failed\n");
    exit(1);
  }

  printf("device found\n");

  if (control_query_version(&version) != CONTROL_SUCCESS) {
    printf("control query version failed\n");
    exit(1);
  }
  if (version != CONTROL_VERSION) {
    printf("version expected 0x%X, received 0x%X\n", CONTROL_VERSION, version);
  }

  printf("started\n");
  for (size_t i = 0; i < sizeof(payload); i++) {
    payload[i] = (uint8_t)(i + 1);
  }

  /* Send four packets */
  for (uint8_t j = 0; j < 4; j++) {
    payload[0] = j;
    if (control_write_command(RESOURCE_ID, CONTROL_CMD_SET_WRITE(0), payload, sizeof(payload)) != CONTROL_SUCCESS) {
      printf("control write command failed\n");
      exit(1);
    }

    pause_short();

    unsigned char read_payload[100];
    if (control_read_command(RESOURCE_ID, CONTROL_CMD_SET_READ(0), read_payload, sizeof(read_payload)) != CONTROL_SUCCESS) {
      printf("control read command failed\n");
      exit(1);
    }

    for (size_t k = 0; k < sizeof(read_payload); k++) {
      if (read_payload[k] != j) {
        printf("control read command returned the wrong value, expected %d, returned %d\n", j, read_payload[k]);
        exit(1);
      }
    }
    printf("Written and read back command with payload: 0x%02X\n", payload[0]);

  }

  control_cleanup_usb();
  printf("done\n");

  return 0;
}
