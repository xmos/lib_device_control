// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"
#include "control_shared.h"
#include "control_host_support.h"
#include "resource.h"
#include "support.h"
#include "support_inline.h"
#include "user_task.h"

#define PRINT_ALL 0

void test_client(client interface control i[3], chanend c_user_task[3])
{
  uint32_t buf[64];
  struct command c1, c2;
  struct options o;
  unsigned lenin;
  unsigned lenout;
  int timeout;
  timer tmr;
  int t, j;
  uint8_t *unsafe buf_ptr;
  int fails;
  control_ret_t ret, ret1;
  int check_result;
  chan d;

  memset(buf, 0, sizeof(buf));

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

            if (c1.payload_size == 0)
              lenin = control_xscope_create_upload_buffer(buf, c1.cmd, c1.resid,
                                                          NULL, 0);
            else
              lenin = control_xscope_create_upload_buffer(buf, c1.cmd, c1.resid,
                                                          c1.payload, c1.payload_size);

            /* make a processing call, catch and record it, or timeout if none of the
             * test tasks actually receives a command (e.g. when resource ID not found)
             */
            unsafe {
              buf_ptr = (uint8_t*)buf;

              tmr :> t;
              timeout = 0;
              par {
                d <: control_process_xscope_upload((uint8_t*)buf_ptr, sizeof(buf), lenin, lenout, i);
                { const size_t header_len = sizeof(struct control_xscope_response);
                  struct control_xscope_response *resp = (struct control_xscope_response*)buf;
                  uint8_t *payload = (uint8_t*)(resp + 1);

                  select {
                    case drive_user_task_commands(c2, c1, c_user_task, o.read_cmd);
                    case tmr when timerafter(t + 500) :> void:
                      timeout = 1;
                      break;
                  }

                  /* retrieve received payload for a read command */
                  if (!timeout && IS_CONTROL_CMD_READ(c2.cmd)) {
                    for (j = 0; j < c2.payload_size; j++) {
                      c2.payload[j] = payload[j];
                    }
                  }

                  /* retrieve return code from processing call and as
                   * embedded in the xSCOPE response
                   */
                  ret1 = resp->ret;
                  d :> ret;

                  check_result = check(o, c1, c2, timeout, ret, 3);

		  if (check_result != 0) {
		    fails += 1;
		  }

		  /* additional checks specific to xSCOPE */
		  if (fails != 0) {
		    if (ret1 != CONTROL_SUCCESS) {
		      printf("response contained return code %d\n", ret1);
		      fails += 1;
		    }
		    else if (ret1 != ret) {
		      printf("mismatching return codes - processing function %d, response %d\n",
			ret, ret1);

		      fails += 1;
		    }
		    else if (o.read_cmd && ret == CONTROL_SUCCESS) {
		      if (lenout != header_len + c2.payload_size) {
			printf("wrong response length %d, expected %d\n",
			  lenout, header_len + c2.payload_size);

			fails += 1;
		      }
		    }
		    else {
		      if (lenout != header_len) {
			printf("wrong response length %d, expected %d\n",
			  lenout, header_len);

			fails += 1;
		      }
		    }
		  }
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
    printf("ERROR - %d fails found\n", fails);
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
