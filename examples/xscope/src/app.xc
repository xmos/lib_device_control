// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include "control.h"
#include "app.h"

#define DEBUG_UNIT DEVICE
#include "debug_print.h"


void app(server interface control i_control)
{
  unsigned num_commands;
  int i;

  debug_printf("[DEV] started\n");
  #ifdef ERRONEOUS_DEVICE
  debug_printf("[DEV] generate errors\n");
  #endif

  num_commands = 0;
  uint8_t test_value = 0;
  while (1) {
    select {
      case i_control.register_resources(
        control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
        unsigned &num_resources):
        {
          resources[0] = RESOURCE_ID;
          num_resources = 1;
          break;
        }

      case i_control.write_command(
        control_resid_t resid, 
        control_cmd_t cmd,
        const uint8_t payload[payload_len], 
        unsigned payload_len) -> control_ret_t ret:
        {
          num_commands++;
          #ifdef ERRONEOUS_DEVICE
          if ((num_commands % 3) == 0)
            resid += 1;
          #endif
          debug_printf("[DEV] %u write: %02x %02x %02x ", num_commands, resid, cmd, payload_len);
          for (i = 0; i < payload_len; i++) {
            debug_printf("%02x", payload[i]);
          }
          debug_printf("\n");
          
          if (resid != RESOURCE_ID) {
            debug_printf("[DEV] unrecognised resource ID %d\n", resid);
            ret = CONTROL_ERROR;
            break;
          }
          test_value = payload[0];
          ret = CONTROL_SUCCESS;
          break;
        }

      case i_control.read_command(
        control_resid_t resid, 
        control_cmd_t cmd,
        uint8_t payload[payload_len], 
        unsigned payload_len) -> control_ret_t ret:
        {
          num_commands++;
          #ifdef ERRONEOUS_DEVICE
          if ((num_commands % 3) == 0)
            resid += 1;
          #endif
          debug_printf("[DEV] %u read: %02x %02x %02x\n", num_commands, resid, cmd, payload_len);
          if (resid != RESOURCE_ID) {
            debug_printf("[DEV] unrecognised resource ID %d\n", resid);
            ret = CONTROL_ERROR;
            break;
          }
          if (payload_len != 1) {
            debug_printf("[DEV] expecting 1 read byte, not %d\n", payload_len);
            ret = CONTROL_ERROR;
            break;
          }
          payload[0] = test_value;
          ret = CONTROL_SUCCESS;
          break;
        }
    }
  }
}
