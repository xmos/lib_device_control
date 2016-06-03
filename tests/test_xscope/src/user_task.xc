// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <stdint.h>
#include "control.h"
#include "user_task.h"

void user_task(server interface control i, chanend d)
{
  int j;

  while (1) {
    select {
      case i.register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                                unsigned &num_resources):
        d :> num_resources;
        for (int k = 0; k < num_resources; k++) {
          unsigned x;
          d :> x;
          resources[k] = x;
        }
        break;

      case i.write_command(control_resid_t resid, control_cmd_t cmd,
                           const uint8_t data[n], unsigned n) -> control_res_t res:
        d <: cmd;
        d <: resid;
        d <: n;
        for (j = 0; j < n; j++) {
          d <: data[j];
        }
        res = CONTROL_SUCCESS;
        break;

      case i.read_command(control_resid_t resid, control_cmd_t cmd,
                          uint8_t data[n], unsigned n) -> control_res_t res:
        d <: cmd;
        d <: resid;
        d <: n;
        for (j = 0; j < n; j++) {
          uint8_t x; /* must use temporary variable (bug 17370) */
          d :> x;
          data[j] = x;
        }
        res = CONTROL_SUCCESS;
        break;
    }
  }
}

