// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdio.h>
#include <stdlib.h>
#include "signals.h"
#include "control_host.h"
#include "resource.h"
#include "pause.h"

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

  signals_init();
  signals_setup_int(shutdown);

  if (control_init_usb(0x20B1, 0x1010) != CONTROL_SUCCESS) {
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

  while (!done) {
    for (i = 0; !done && i < 4; i++) {
      payload[0] = 1;
      if (control_write_command(RESOURCE_ID, CONTROL_CMD_SET_WRITE(0), payload, 1) != CONTROL_SUCCESS) {
        printf("control write command failed\n");
        exit(1);
      }
      printf("W");
      fflush(stdout);

      pause_short();

      if (control_read_command(RESOURCE_ID, CONTROL_CMD_SET_READ(0), payload, 4) != CONTROL_SUCCESS) {
        printf("control read command failed\n");
        exit(1);
      }
      printf("R");
      fflush(stdout);

      pause_long();
    }
  }

  control_cleanup_usb();

  return 0;
}
