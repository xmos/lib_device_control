// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"
#include "control_transport.h"
#include "control_host.h"
#include "user_task.h"

#define PRINT_ALL 0

/* resource ID that includes interface number of given test task
 * and which resource in given task it is, if the task has more than one
 */
#define RESID(if_num, res_in_if) (0x80 | ((if_num) << 4) | ((res_in_if) + 1))
#define BADID 0xFF

struct options {
  int with_payload;
  int res_in_if;
  int read_cmd;
  int bad_id;
};

struct command {
  unsigned ifnum;
  control_resid_t resid;
  control_cmd_t cmd;
  uint8_t payload[8];
  unsigned payload_size;
};

void make_command(struct command &c, const struct options &o)
{
  c.resid = RESID(c.ifnum, o.res_in_if);

  if (o.read_cmd)
    c.cmd = CONTROL_CMD_SET_READ(0);
  else
    c.cmd = CONTROL_CMD_SET_WRITE(0);

  if (o.bad_id)
    c.resid = BADID;

  if (o.with_payload)
    c.payload_size = sizeof(c.payload);
  else
    c.payload_size = 0;
}

int check(const struct options &o,
          const struct command &c1, const struct command &c2,
          int timeout, control_res_t res)
{
  int timeout_expected;
  int fail;
  int j;

  timeout_expected = o.bad_id || c1.ifnum > 1 || o.res_in_if > 1;
  fail = 0;

  if (timeout_expected) {
    if (!timeout) {
      printf("unexpected\n");
      fail = 1;
    }
  }
  else {
    if (timeout) {
      printf("timeout\n");
      fail = 1;
    }
    else if (c1.ifnum != c2.ifnum || c1.cmd != c2.cmd || c1.resid != c2.resid || c1.payload_size != c2.payload_size) {
      printf("mismatch\n");
      fail = 1;
    }
    else {
      for (j = 0; j < c2.payload_size; j++) {
        if (c2.payload[j] != c1.payload[j]) {
          printf("payload mismatch: byte %d received 0x%02X expected 0x%02X\n",
            j, c2.payload[j], c1.payload[j]);
          fail = 1;
        }
      }
      if (res != CONTROL_SUCCESS) {
        printf("processing function returned %d\n", res);
        fail = 1;
      }
    }
  }

  if (fail) {
    if (!timeout) {
      printf("received ifnum %d cmd %d resid 0x%X payload %d\n",
        c2.ifnum, c2.cmd, c2.resid, c2.payload_size);
    }
  }
#if !PRINT_ALL
  if (fail)
#endif
  {
    printf("issued ifnum %d cmd %d resid 0x%X (resource %d) payload %d\n",
      c1.ifnum, c1.cmd, c1.resid, o.res_in_if, c1.payload_size);
  }

  return fail;
}

select drive_user_task(struct command &c2, const struct command &c1, chanend d[2], int read_cmd)
{
  case d[int k] :> c2.cmd: {
    int j;

    d[k] :> c2.resid;
    d[k] :> c2.payload_size;
    if (read_cmd) {
      for (j = 0; j < sizeof(c1.payload) && j < c2.payload_size; j++) {
        d[k] <: c1.payload[j];
      }
    }
    else {
      for (j = 0; j < sizeof(c1.payload) && j < c2.payload_size; j++) {
        d[k] :> c2.payload[j];
      }
    }
    c2.ifnum = k;
    break;
  }
}

void test_client(client interface control i[2], chanend c_user_task[2])
{
  uint16_t windex, wvalue, wlength;
  struct command c1, c2;
  struct options o;
  int timeout;
  timer tmr;
  int t, j;
  uint8_t *unsafe payload_ptr;
  int fails;
  control_res_t res;
  chan d;

  for (j = 0; j < 8; j++) {
    c1.payload[j] = j;
  }

  /* trigger a registration call, catch it and supply resource IDs to register */
  par {
    control_init(i, 2);
    par (int j = 0; j < 2; j++) {
      { c_user_task[j] <: 2;
        c_user_task[j] <: RESID(j, 0);
        c_user_task[j] <: RESID(j, 1);
      }
    }
  }

  fails = 0;

  for (c1.ifnum = 0; c1.ifnum < 3; c1.ifnum++) {
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
                      (uint8_t*)payload_ptr, i, 2);
                  else
                    d <: control_process_usb_set_request(windex, wvalue, wlength,
                      (uint8_t*)payload_ptr, i, 2);
                }
                { select {
                    case drive_user_task(c2, c1, c_user_task, o.read_cmd);
                    case tmr when timerafter(t + 3000) :> void:
                      timeout = 1;
                      break;
                  }
                  d :> res;
                  fails += check(o, c1, c2, timeout, res);
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
    exit(1);
  }
}

int main(void)
{
  interface control i[2];
  chan c_user_task[2];
  par {
    test_client(i, c_user_task);
    user_task(i[0], c_user_task[0]);
    user_task(i[1], c_user_task[1]);
  }
  return 0;
}
