// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"
#include "control_transport.h"
#include "control_host_support.h"
#include "resource.h"
#include "support.h"
#include "support_inline.h"
#include "user_task.h"

void test_client(client interface control i[3], chanend c_user_task[3])
{
  uint8_t buf[I2C_TRANSACTION_MAX_BYTES];
  size_t buf_len;
  struct command c1, c2;
  struct options o;
  int timeout;
  timer tmr;
  int t, j;
  uint8_t *unsafe payload_ptr;
  int fails;
  unsigned payload_size;
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

            buf_len = control_build_i2c_data(buf, c1.resid, c1.cmd, c1.payload, c1.payload_size);

            /* make a sequence of processing calls, catch the result and record it */
            unsafe {
              payload_size = c1.payload_size;
              if (o.read_cmd)
                payload_ptr = c2.payload;

              tmr :> t;
              timeout = 0;
              par {
                { control_ret_t ret;
                  ret = CONTROL_SUCCESS;
                  ret |= control_process_i2c_write_start(i);
                  for (j = 0; j < buf_len; j++) {
                    ret |= control_process_i2c_write_data(buf[j], i);
                  }
                  if (o.read_cmd && payload_size > 0) {
                    ret |= control_process_i2c_read_start(i);
                    for (j = 0; j < payload_size; j++) {
                      ret |= control_process_i2c_read_data(payload_ptr[j], i);
                    }
                  }
                  ret |= control_process_i2c_stop(i);
                  d <: ret;
                }
                { control_ret_t ret;
                  select {
                    case drive_user_task_commands(c2, c1, c_user_task, o.read_cmd);
                    case tmr when timerafter(t + 2000) :> void:
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
    { delay_microseconds(10000);
      printf("ERROR - test timeout\n");
      exit(1);
    }
  }
  return 0;
}
