// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
#include "control.h"
#include "app.h"

void app(server interface control i_control)
{
  unsigned num_commands;
  int i;

  const unsigned char rx_expected_payload[4] = {0xaa, 0xff, 0x55, 0xed};

  printf("started\n");
#ifdef ERRONEOUS_DEVICE
  printf("generate errors\n");
#endif

  num_commands = 0;

  while (num_commands!=8) {
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
        printf("%u: W %d %d %d,\t=", num_commands, resid, cmd, payload_len);
        for (i = 0; i < payload_len; i++) {
          printf(" %02x", payload[i]);
          if (payload[i] != rx_expected_payload[i]) {
            printf("\nERROR - incorrect data received - expecting 0x%x\n", rx_expected_payload[i]);
            ret = CONTROL_ERROR;
            break;
          }
        }
        printf("\n");
        if (resid != RESOURCE_ID) {
          printf("unrecognised resource ID %d\n", resid);
          ret = CONTROL_ERROR;
          break;
        }
        ret = CONTROL_SUCCESS;
        break;

      case i_control.read_command(control_resid_t resid, control_cmd_t cmd,
                                  uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret:
        num_commands++;
#ifdef ERRONEOUS_DEVICE
        if ((num_commands % 3) == 0)
          resid += 1;
#endif
        payload[0] = 0x12;
        payload[1] = 0x34;
        payload[2] = 0x56;
        payload[3] = 0x78;
        printf("%u: R %d %d %d,\t=", num_commands, resid, cmd, payload_len);
        for (i = 0; i < payload_len; i++) {
          printf(" %02x", payload[i]);
        }
        printf("\n");
        if (resid != RESOURCE_ID) {
          printf("unrecognised resource ID %d\n", resid);
          ret = CONTROL_ERROR;
          break;
        }
        if (payload_len != 4) {
          printf("ERROR - expecting 4 read bytes, not %d\n", payload_len);
          ret = CONTROL_ERROR;
          break;
        }
        ret = CONTROL_SUCCESS;
        break;
    }
  }
  _Exit(0);
}
