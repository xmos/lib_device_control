// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"
#include "control_shared.h"
#include "../../../lib_device_control/host/control_host_support.h"
#include "resource.h"
#include "support.h"
#include "support_inline.h"
#include "user_task.h"

void test_client(client interface control i[3], chanend c_user_task[3])
{
  uint16_t windex, wvalue, wlength;
  struct command c1, c2;
  struct options o;
  int timeout;
  timer tmr;
  int t, j;
  uint8_t *unsafe payload_ptr;
  int fails;
  control_ret_t ret;
  chan d;

  for (j = 0; j < 8; j++) {
    c1.payload[j] = j;
  }

  control_init();

  /* trigger a registration call, catch it and supply resource IDs to register */
  par {
    control_register_resources(i, 3);
    drive_user_task_registration(c_user_task, 3);
  }

  fails = 0;

  for (c1.ifnum = 0; c1.ifnum < 4; c1.ifnum++) {
    for (o.read_cmd = 0; o.read_cmd < 2; o.read_cmd++) {
      for (o.res_in_if = 0; o.res_in_if < 3; o.res_in_if++) {
        for (o.bad_id = 0; o.bad_id < 2; o.bad_id++) {
          for (o.with_payload = 0; o.with_payload < 2; o.with_payload++) {
            make_command(c1, o);

            control_usb_fill_header(&windex, &wvalue, &wlength, c1.resid, c1.cmd,
              c1.payload_size);

            /* make a processing call, catch and record it, or timeout if none of the
             * test tasks actually receives a command (e.g. when resource ID not found)
             */
            unsafe {
              if (o.read_cmd)
                payload_ptr = c2.payload;
              else
                payload_ptr = c1.payload;

              tmr :> t;
              timeout = 0;
              par {
                { if (o.read_cmd)
                    d <: control_process_usb_get_request(windex, wvalue, wlength,
                      (uint8_t*)payload_ptr, i);
                  else
                    d <: control_process_usb_set_request(windex, wvalue, wlength,
                      (uint8_t*)payload_ptr, i);
                }
                { select {
                    case drive_user_task_commands(c2, c1, c_user_task, o.read_cmd);
                    case tmr when timerafter(t + 500) :> void:
                      timeout = 1;
                      break;
                  }
                  d :> ret;
                  fails += check(o, c1, c2, timeout, ret, 3);
                }
              }
            }
          }
        }
      }
    }
  }

  if (fails == 0) {
    printf("Success!\n");
    exit(0);
  }
  else {
    printf("ERROR - %d fails recorded!\n", fails);
    exit(1);
  }
}

int main(void)
{
  interface control i[3];
  chan c_user_task[3];
  par {
    test_client(i, c_user_task);
    user_task(i[0], c_user_task[0]);
    user_task(i[1], c_user_task[1]);
    user_task(i[2], c_user_task[2]);
    { delay_microseconds(5000);
      printf("ERROR - test timeout\n");
      exit(1);
    }
  }
  return 0;
}
