// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <stdint.h>
#include <stdio.h>
#include "control.h"
#include "user_task.h"

void user_task(server interface control i, chanend c)
{
  int j;

  while (1) {
    select {
      case i.register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                                unsigned &num_resources):
        c :> num_resources;
        for (int k = 0; k < num_resources; k++) {
          unsigned x;
          c :> x;
          resources[k] = x;
        }
        break;

      case i.write_command(control_resid_t resid, control_cmd_t cmd,
                           const uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret:
        c <: cmd;
        c <: resid;
        c <: payload_len;
        for (j = 0; j < payload_len; j++) {
          c <: payload[j];
        }
        ret = CONTROL_SUCCESS;
        break;

      case i.read_command(control_resid_t resid, control_cmd_t cmd,
                          uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret:
        c <: cmd;
        c <: resid;
        c <: payload_len;
        for (j = 0; j < payload_len; j++) {
          uint8_t x; /* must use temporary variable (bug 17370) */
          c :> x;
          payload[j] = x;
        }
        ret = CONTROL_SUCCESS;
        break;
    }
  }
}

