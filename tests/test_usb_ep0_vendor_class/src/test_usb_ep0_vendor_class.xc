// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"
#include "control_transport.h"
#include "control_host.h"

/* resource ID that includes interface number of given test task
 * and which resource in given task it is, if the task has more than one
 */
#define RESID(if_num, res_in_if) (0xCAFEBD00 | ((if_num) << 4) | ((res_in_if) + 1))
#define BADID 0x55555555
#define IDX(if_num, res_in_if) ((if_num) * 2 + (res_in_if) + 1)
#define BADIDX 0x55

void test_client(client interface control i[2], chanend c[2])
{
  uint8_t payload1[8], payload2[8];
  control_resid_t resid1, resid2;
  control_cmd_t cmd1, cmd2;
  uint16_t windex, wvalue, wlength;
  unsigned ifnum1, ifnum2;
  int timeout;
  int timeout_expected;
  unsigned payload1_size, payload2_size;
  timer tmr;
  int with_payload;
  int res_in_if;
  int read_cmd;
  int bad_id;
  int t, j;
  int fail;
  int idx;

  for (j = 0; j < 8; j++) {
    payload1[j] = j;
  }

  /* trigger a registration call, catch it and supply resource IDs to register */
  par {
    { c[0] <: 2;
      c[0] <: RESID(0, 0);
      c[0] <: RESID(0, 1);
    }
    { c[1] <: 2;
      c[1] <: RESID(1, 0);
      c[1] <: RESID(1, 1);
    }
    control_init(i, 2);
  }

  for (ifnum1 = 0; ifnum1 < 3; ifnum1++) {
    for (read_cmd = 0; read_cmd < 2; read_cmd++) {
      for (res_in_if = 0; res_in_if < 3; res_in_if++) {
        for (bad_id = 0; bad_id < 2; bad_id++) {
          for (with_payload = 0; with_payload < 2; with_payload++) {
            resid1 = RESID(ifnum1, res_in_if);
            idx = IDX(ifnum1, res_in_if);

            if (read_cmd)
              cmd1 = CONTROL_CMD_SET_READ(0);
            else
              cmd1 = CONTROL_CMD_SET_WRITE(0);

            if (bad_id) {
              resid1 = BADID;
            }

            if (bad_id || ifnum1 > 1 || res_in_if > 1) {
              idx = BADIDX;
            }

            if (with_payload)
              payload1_size = sizeof(payload1);
            else
              payload1_size = 0;

            control_usb_ep0_fill_header(&windex, &wvalue, &wlength, idx, cmd1,
              payload1_size);

            /* make a processing call, catch and record it, or timeout if none of the
             * test tasks actually receives a command (e.g. when resource ID not found)
             */
            tmr :> t;
            timeout = 0;
            if (read_cmd) {
              par {
                  control_process_usb_ep0_get_request(windex, wvalue, wlength,
                    payload2, i, 2);
                  select {
                    case c[int k] :> cmd2:
                      c[k] :> resid2;
                      c[k] :> payload2_size;
                      for (j = 0; j < sizeof(payload1) && j < payload2_size; j++) {
                        c[k] <: payload1[j];
                      }
                      ifnum2 = k;
                      break;
                    case tmr when timerafter(t + 3000) :> void:
                      timeout = 1;
                      break;
                  }
              }
            }
            else {
              par {
                control_process_usb_ep0_set_request(windex, wvalue, wlength,
                  payload1, i, 2);
                select {
                  case c[int k] :> cmd2:
                    c[k] :> resid2;
                    c[k] :> payload2_size;
                    for (j = 0; j < sizeof(payload1) && j < payload2_size; j++) {
                      c[k] :> payload2[j];
                    }
                    ifnum2 = k;
                    break;
                  case tmr when timerafter(t + 3000) :> void:
                    timeout = 1;
                    break;
                }
              }
            }

            timeout_expected = bad_id || ifnum1 > 1 || res_in_if > 1;
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
              else if (ifnum1 != ifnum2 || cmd1 != cmd2 || resid1 != resid2 || payload1_size != payload2_size) {
                printf("mismatch\n");
                fail = 1;
              }
              else {
                for (j = 0; j < payload2_size; j++) {
                  if (payload2[j] != payload1[j]) {
                    printf("payload mismatch: byte %d received 0x%02X expected 0x%02X\n",
                      j, payload2[j], payload1[j]);
                    fail = 1;
                  }
                }
              }
            }

            if (fail) {
              if (!timeout) {
                printf("received ifnum %d cmd %d resid 0x%X payload %d\n",
                  ifnum2, cmd2, resid2, payload2_size);
              }
              printf("isssued ifnum %d cmd %d resid 0x%X (resource %d) payload %d\n",
                ifnum1, cmd1, resid1, res_in_if, payload1_size);
            }
          }
        }
      }
    }
  }

  printf("Success!\n");
  exit(0);
}

void test_task(server interface control i, chanend c)
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
                           const uint8_t data[n], unsigned n) -> control_res_t res:

        c <: cmd;
        c <: resid;
        c <: n;
        for (j = 0; j < n; j++) {
          c <: data[j];
        }
        res = CONTROL_SUCCESS;
        break;

      case i.read_command(control_resid_t resid, control_cmd_t cmd,
                          uint8_t data[n], unsigned n) -> control_res_t res:
        c <: cmd;
        c <: resid;
        c <: n;
        for (j = 0; j < n; j++) {
          uint8_t x; /* BUG fails when written as "c :> data[j]" */
          c :> x;
          data[j] = x;
        }
        res = CONTROL_SUCCESS;
        break;
    }
  }
}

int main(void)
{
  interface control i[2];
  chan c[2];
  par {
    test_client(i, c);
    test_task(i[0], c[0]);
    test_task(i[1], c[1]);
  }
  return 0;
}
