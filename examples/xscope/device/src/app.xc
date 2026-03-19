// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <stdio.h>
#include <stdint.h>
#include <assert.h>


#include "control.h"
#include "app.h"
#include "resource.h"

void app(server interface control i_control)
{
  unsigned num_commands;

  printf("started\n");
#ifdef ERRONEOUS_DEVICE
  printf("generate errors\n");
#endif

  num_commands = 0;
  uint8_t test_value = 0;
  while (1) {
    select {
      case i_control.register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                                        unsigned &num_resources):
        resources[0] = RESOURCE_ID;
        num_resources = 1;
        break;

      case i_control.write_command(control_resid_t resid, control_cmd_t cmd,
                                   const uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret:
        num_commands++;
#ifdef ERRONEOUS_DEVICE
        if ((num_commands % 3) == 0)
          resid += 1;
#endif
        printf("%u: W %d %d %d,", num_commands, resid, cmd, payload_len);
        for (unsigned i = 0; i < payload_len; i++) {
          printf(" %02x", payload[i]);
        }
        printf("\n");
        /* DOC-TAG: WRITE */
        if (resid != RESOURCE_ID) {
          printf("unrecognised resource ID %d\n", resid);
          ret = CONTROL_ERROR;
          break;
        }
        if (payload_len > 0) {
          test_value = payload[0];
        } else {
          test_value = 0;
        }
        ret = CONTROL_SUCCESS;
        break;
        /* DOC-TAG: WRITE_END */

      case i_control.read_command(control_resid_t resid, control_cmd_t cmd,
                                  uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret:
        num_commands++;
#ifdef ERRONEOUS_DEVICE
        if ((num_commands % 3) == 0)
          resid += 1;
#endif
        printf("%u: R %d %d %d\n", num_commands, resid, cmd, payload_len);
        /* DOC-TAG: READ */
        if (resid != RESOURCE_ID) {
          printf("unrecognised resource ID %d\n", resid);
          ret = CONTROL_ERROR;
          break;
        }
        // Simple test: fill the payload with the last written value
        for (int i = 0; i < payload_len; i++) {
          payload[i] = test_value;
        }
        ret = CONTROL_SUCCESS;
        break;
        /* DOC-TAG: READ_END */
    }
  }
}
