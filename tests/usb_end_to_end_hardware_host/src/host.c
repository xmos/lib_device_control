// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "control_host.h"
#include "signals.h"
#include "resource.h"
#include "util.h"

int done = 0;

void shutdown(void)
{
  done = 1;
}

int main(void)
{
  control_version_t version;
  unsigned char payload[4];
  int i;
  const unsigned char rx_expected_payload[4] = {0x12, 0x34, 0x56, 0x78};


  signals_init();
  signals_setup_int(shutdown);

  if (control_init_usb(0x20B1, 0x1010, 0) != CONTROL_SUCCESS) {
    printf("ERROR - control init failed\n");
    exit(1);
  }

  printf("device found\n");

  if (control_query_version(&version) != CONTROL_SUCCESS) {
    printf("control query version failed\n");
    exit(1);
  }
  if (version != CONTROL_VERSION) {
    printf("ERROR - version expected 0x%X, received 0x%X\n", CONTROL_VERSION, version);
  }

  printf("started\n");

  for (i = 0; i < 4; i++) {
    payload[0] = 0xaa;
    payload[1] = 0xff;
    payload[2] = 0x55;
    payload[3] = 0xed;
    if (control_write_command(RESOURCE_ID, CONTROL_CMD_SET_WRITE(0), payload, 4) != CONTROL_SUCCESS) {
      printf("control write command failed\n");
      exit(1);
    }
    printf("Written payload\t= %2x, %2x, %2x, %2x\n", payload[0], payload[1], payload[2], payload[3]);
    fflush(stdout);

    pause_short();

    if (control_read_command(RESOURCE_ID, CONTROL_CMD_SET_READ(0), payload, 4) != CONTROL_SUCCESS) {
      printf("control read command failed\n");
      exit(1);
    }
    printf("Read payload\t= %2x, %2x, %2x, %2x\n", payload[0], payload[1], payload[2], payload[3]);
    if (memcmp(rx_expected_payload, payload, 4)) {
      printf("ERROR - incorrect payload received from device\n");
      printf("Expecting \t= %2x, %2x, %2x, %2x\n", rx_expected_payload[0], rx_expected_payload[1], 
        rx_expected_payload[2], rx_expected_payload[3]);
    }
    fflush(stdout);

    pause_long();
  }

  control_cleanup_usb();
  printf("done\n");

  return 0;
}
