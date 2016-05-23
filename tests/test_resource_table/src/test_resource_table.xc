// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"

#define RESID(if_num, res_num_in_if) (0xCAFEBD00 | ((if_num) << 4) | ((res_num_in_if) + 1))
#define CMD 0
#define DATA 0

void test_client(client interface control i[2], chanend c)
{
  control_resid_t resid, received;
  unsigned buf[64];
  unsigned lenout;
  unsigned ifnum;
  timer tmr;
  int j, k, t;

  control_init(i, 2);

  for (j = 0; j < 2; j++) {
    for (k = 0; k < 2; k++) {
      resid = RESID(j, k);
      buf[0] = resid;
      buf[1] = CMD;
      buf[2] = 4;
      buf[3] = DATA;

      control_process_xscope_upload((buf, uint8_t[]), 16, lenout, i, 2);

      tmr :> t;
      select {
        case c :> received:
          c :> ifnum;
          break;

        case tmr when timerafter(t + 1000) :> void:
          printf("timeout - message for 0x%X not received\n", resid);
          exit(1);
          break;
      }

      if (received != resid) {
        printf("received 0x%X, expected 0x%X\n", received, resid);
        exit(1);
      }

      if (ifnum != j) {
        printf("received on inteface %d, expected %d\n", ifnum, j);
        exit(1);
      }
    }
  }

  printf("Success!\n");
}

void test_task(server interface control i[2], chanend c)
{
  while (1) {
    select {
      case i[int j].register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                                       unsigned &num_resources):
        resources[0] = RESID(j, 0);
        resources[1] = RESID(j, 1);
        num_resources = 2;
        break;

      case i[int j].write_command(control_resid_t resid, control_cmd_t cmd,
                                  const uint8_t data[n], unsigned n) -> control_res_t res:
        c <: j;
        c <: resid;
        res = CONTROL_SUCCESS;
        break;

      case i[int j].read_command(control_resid_t resid, control_cmd_t cmd,
                                 uint8_t data[n], unsigned n) -> control_res_t res:
        printf("unexpected read command\n");
        exit(1);
        res = CONTROL_ERROR;
        break;
    }
  }
}

int main(void)
{
  interface control i[2];
  chan c;
  par {
    test_client(i, c);
    test_task(i, c);
  }
  return 0;
}
