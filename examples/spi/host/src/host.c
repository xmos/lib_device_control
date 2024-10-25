// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "control_host.h"
#include "control_transport_shared.h" // for SPI_DATA_MAX_BYTES
#include "resource.h"
#include "util.h"
#include <bcm2835.h>

#define INVALID_CONTROL_VERSION 0xFF
#define PAYLOAD_LEN 1

int main(void)
{
  control_version_t version = INVALID_CONTROL_VERSION;
  assert(PAYLOAD_LEN > 0 && PAYLOAD_LEN < SPI_DATA_MAX_BYTES);
  unsigned char payload[PAYLOAD_LEN];
  uint8_t i;

  if (control_init_spi_pi(SPI_MODE_3, BCM2835_SPI_CLOCK_DIVIDER_8192, 2) != CONTROL_SUCCESS) {
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
  printf("using payload of size %d\n", PAYLOAD_LEN);

  for (i = 0; i < 4; i++) {
    for (int j = 0; j < PAYLOAD_LEN; j++) {
      payload[j] = i+j;

    }

    if (control_write_command(RESOURCE_ID, CONTROL_CMD_SET_WRITE(0), payload, PAYLOAD_LEN) != CONTROL_SUCCESS) {
      printf("control write command failed\n");
      exit(1);
    }

    pause_short();

    if (control_read_command(RESOURCE_ID, CONTROL_CMD_SET_READ(0), payload, PAYLOAD_LEN) != CONTROL_SUCCESS) {
      printf("control read command failed\n");
      exit(1);
    }
    for (int j = 0; j < PAYLOAD_LEN; j++) {
      if (payload[j] != i+j) {
        printf("control read command returned the wrong value, expected %d, returned %d\n", i+j, payload[j]);
        exit(1);
      }
    }
    printf("Written and read back command with payload: ");
    for (int j = 0; j < PAYLOAD_LEN; j++) {
      printf("%02X ", payload[j]);
    }
    printf("\n");
  }

  control_cleanup_spi();
  printf("done\n");

  return 0;
}
