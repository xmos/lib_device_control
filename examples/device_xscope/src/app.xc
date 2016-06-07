// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include "control.h"
#include "app.h"

void app(server interface control i_control)
{
  unsigned num_commands;
  int i;

  printf("started\n");

  num_commands = 0;

  while (1) {
    select {
      case i_control.register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                                        unsigned &num_resources):
        resources[0] = RESOURCE_ID;
        num_resources = 1;
        break;

      case i_control.write_command(control_resid_t r, control_cmd_t c,
                                   const uint8_t data[n], unsigned n) -> control_ret_t ret:
        printf("%u: W %d %d %d,", num_commands, r, c, n);
        for (i = 0; i < n; i++) {
          printf(" %02x", data[i]);
        }
        printf("\n");
        if (r != RESOURCE_ID) {
          printf("unrecognised resource ID %d\n", r);
          ret = CONTROL_ERROR;
          break;
        }
        num_commands++;
        ret = CONTROL_SUCCESS;
        break;

      case i_control.read_command(control_resid_t r, control_cmd_t c,
                                  uint8_t data[n], unsigned n) -> control_ret_t ret:
        printf("%u: R %d %d %d\n", num_commands, r, c, n);
        if (r != RESOURCE_ID) {
          printf("unrecognised resource ID %d\n", r);
          ret = CONTROL_ERROR;
          break;
        }
        if (n != 4) {
          printf("expecting 4 read bytes, not %d\n", n);
          ret = CONTROL_ERROR;
          break;
        }
        data[0] = 0x12;
        data[1] = 0x34;
        data[2] = 0x56;
        data[3] = 0x78;
        num_commands++;
        ret = CONTROL_SUCCESS;
        break;
    }
  }
}
