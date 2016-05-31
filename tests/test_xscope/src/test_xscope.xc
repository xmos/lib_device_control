// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"
#include "control_transport.h"
#include "control_host.h"
#include "user_task.h"

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

void check(const struct options &o,
           const struct command &c1, const struct command &c2,
           int timeout)
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
    }
  }

  if (fail) {
    if (!timeout) {
      printf("received ifnum %d cmd %d resid 0x%X payload %d\n",
        c2.ifnum, c2.cmd, c2.resid, c2.payload_size);
    }
    printf("isssued ifnum %d cmd %d resid 0x%X (resource %d) payload %d\n",
      c1.ifnum, c1.cmd, c1.resid, o.res_in_if, c1.payload_size);
  }
}

select receive_command(struct command &c2, const struct command &c1, chanend d[2])
{
  case d[int k] :> c2.cmd: {
    int j;

    d[k] :> c2.resid;
    d[k] :> c2.payload_size;
    if (IS_CONTROL_CMD_READ(c2.cmd)) {
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

void test_client(client interface control i[2], chanend d[2])
{
  uint32_t buf[XSCOPE_UPLOAD_MAX_WORDS];
  struct command c1, c2;
  struct options o;
  unsigned lenin;
  unsigned lenout;
  int timeout;
  timer tmr;
  int t, j;

  for (j = 0; j < 8; j++) {
    c1.payload[j] = j;
  }

  /* trigger a registration call, catch it and supply resource IDs to register */
  par {
    { d[0] <: 2;
      d[0] <: RESID(0, 0);
      d[0] <: RESID(0, 1);
    }
    { d[1] <: 2;
      d[1] <: RESID(1, 0);
      d[1] <: RESID(1, 1);
    }
    control_init(i, 2);
  }

  for (c1.ifnum = 0; c1.ifnum < 3; c1.ifnum++) {
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
            tmr :> t;
            timeout = 0;
            par {
              control_process_xscope_upload(buf, lenin, lenout, i, 2);
              select {
                case receive_command(c2, c1, d);
                case tmr when timerafter(t + 3000) :> void:
                  timeout = 1;
                  break;
              }
            }
            
            /* retrieve received payload for a read command */
            if (!timeout && IS_CONTROL_CMD_READ(c2.cmd)) {
              for (j = 0; j < c2.payload_size; j++) {
                c2.payload[j] = ((struct control_xscope_packet*)buf)->data.read_bytes[j];
              }
            }

            check(o, c1, c2, timeout);
          }
        }
      }
    }
  }

  printf("Success!\n");
  exit(0);
}

int main(void)
{
  interface control i[2];
  chan d[2];
  par {
    test_client(i, d);
    user_task(i[0], d[0]);
    user_task(i[1], d[1]);
  }
  return 0;
}
