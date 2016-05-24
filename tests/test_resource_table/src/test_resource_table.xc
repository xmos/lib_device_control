// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"
#include "control_transport.h"
#include "control_host.h"

#define RESID(if_num, res_num_in_if) (0xCAFEBD00 | ((if_num) << 4) | ((res_num_in_if) + 1))

void test_client(client interface control i[2], chanend c[2])
{
  uint32_t buf[XSCOPE_UPLOAD_MAX_WORDS];
  control_resid_t resid1, resid2;
  control_cmd_t cmd1, cmd2;
  unsigned ifnum1, ifnum2;
  unsigned lenin;
  unsigned lenout;
  int timeout;
  timer tmr;
  int k, t;
  int bad;

  par {
    control_init(i, 2);
    { c[0] <: 2;
      c[0] <: RESID(0, 0);
      c[0] <: RESID(0, 1);
    }
    { c[1] <: 2;
      c[1] <: RESID(1, 0);
      c[1] <: RESID(1, 1);
    }
  }

  for (ifnum1 = 0; ifnum1 < 2; ifnum1++) {
    for (k = 0; k < 2; k++) {
      for (bad = 0; bad < 2; bad++) {
        resid1 = RESID(ifnum1, k);
        cmd1 = CONTROL_CMD_SET_WRITE(0);

        if (bad)
          resid1 = ~resid1;

        lenin = control_create_xscope_upload_buffer(buf, cmd1, resid1, NULL, 0);

        tmr :> t;
        timeout = 0;
        par {
          control_process_xscope_upload(buf, lenin, lenout, i, 2);
          select {
            case c[int j] :> cmd2:
              c[j] :> resid2;
              ifnum2 = j;
              break;
            case tmr when timerafter(t + 10000) :> void:
              timeout = 1;
              break;
          }
        }

        if (bad) {
          if (!timeout) {
            printf("received message for 0x%X, which was bad ID\n", resid1);
            exit(1);
          }
        }
        else {
          if (timeout) {
            printf("timeout - message for 0x%X not received\n", resid1);
            exit(1);
          }
          if (ifnum2 != ifnum1) {
            printf("received on interface %d, expected %d\n", ifnum2, ifnum1);
            exit(1);
          }
          if (cmd2 != cmd1) {
            printf("received command 0x%X, expected 0x%X\n", cmd2, cmd1);
            exit(1);
          }
          if (resid2 != resid1) {
            printf("received ID 0x%X, expected 0x%X\n", resid2, resid1);
            exit(1);
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
        res = CONTROL_SUCCESS;
        break;

      case i.read_command(control_resid_t resid, control_cmd_t cmd,
                          uint8_t data[n], unsigned n) -> control_res_t res:
        c <: cmd;
        c <: resid;
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
