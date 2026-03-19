// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdio.h>
#include <stdlib.h>

#include "control_host.h"
#include "control_host_util.h"
#include "resource.h"

#define INVALID_CONTROL_VERSION 0xFF

// Payload size can be from 1 to 252 bytes
#define PAYLOAD_SIZE 1

static void exit_error(void)
{
  control_cleanup_xscope();
  exit(1);
}

int main(void)
{
  control_version_t version = INVALID_CONTROL_VERSION;
  unsigned char payload[PAYLOAD_SIZE];

  if (control_init_xscope("localhost", "10101") != CONTROL_SUCCESS) {
    printf("control init failed\n");
    exit_error();
  }

  printf("[HOST] device found\n");

  if (control_query_version(&version) != CONTROL_SUCCESS) {
    printf("control query version failed\n");
    exit_error();
  }
  if (version != CONTROL_VERSION) {
    printf("version expected 0x%X, received 0x%X\n", CONTROL_VERSION, version);
  }

  printf("[HOST] started\n");
  for (size_t i = 0; i < sizeof(payload); i++) {
    payload[i] = (uint8_t)(i + 1);
  }

  for (uint8_t i = 0; i < 4; i++) {
    payload[0] = i;
    if (control_write_command(RESOURCE_ID, CONTROL_CMD_SET_WRITE(0), payload, sizeof(payload)) != CONTROL_SUCCESS) {
      printf("[HOST] control write command failed\n");
      exit_error();
    }

    pause_short();

    if (control_read_command(RESOURCE_ID, CONTROL_CMD_SET_READ(0), payload, sizeof(payload)) != CONTROL_SUCCESS) {
      printf("[HOST] control read command failed\n");
      exit_error();
    }

    if (payload[0] != i) {
      printf("[HOST] control read command returned the wrong value, expected %d, returned %d\n", i, payload[0]);
      exit_error();
    }
    printf("[HOST] Written and read back command with payload: 0x%02X\n", payload[0]);

  }

  control_cleanup_xscope();
  printf("[HOST] done\n");

  return 0;
}
