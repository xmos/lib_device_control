// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <stdio.h>
#include "control.h"
#include "control_transport.h"
#include "resource.h"
#include "support.h"

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
          int timeout, control_ret_t ret)
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
      if (ret != CONTROL_SUCCESS) {
        printf("processing function returned %d\n", ret);
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
