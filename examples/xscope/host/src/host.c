// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifdef HOST_APP // Prevent device app from finding this source
#include <stdio.h>
#include <string.h>
#include <signal.h>
#include <stdlib.h>
#include <stdint.h>
#include "xscope_endpoint.h"
#include "control_host.h"
#include "signals.h"
#include "resource.h"
#include "pause.h"

void shutdown(void)
{
  control_cleanup_xscope();
  exit(0);
}

int main(void)
{
  control_version_t version;
  unsigned char payload[4];
  int i;

  signals_init();
  signals_setup_int(shutdown);

  if (control_init_xscope("localhost", "10101") != CONTROL_SUCCESS) {
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

  while (1) {
    for (i = 0; i < 4; i++) {
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

  return 0;
}
#endif //HOST_APP