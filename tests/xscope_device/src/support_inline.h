// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef SUPPORT_INLINE_H_
#define SUPPORT_INLINE_H_

#include "support.h"

// implementation only (no declaration) as per bug 17386
// due to a related issue, user task channel array size is hardcoded
// ideally the xC syntax would be used like "f(chanend c[n], unsigned n)"
select drive_user_task_commands(struct command &c2, const struct command &c1,
                                chanend c_user_task[3], int read_cmd)
{
  case c_user_task[int k] :> c2.cmd: {
    int j;

    c_user_task[k] :> c2.resid;
    c_user_task[k] :> c2.payload_size;
    if (read_cmd) {
      for (j = 0; j < sizeof(c1.payload) && j < c2.payload_size; j++) {
        c_user_task[k] <: c1.payload[j];
      }
    }
    else {
      for (j = 0; j < sizeof(c1.payload) && j < c2.payload_size; j++) {
        c_user_task[k] :> c2.payload[j];
      }
    }
    c2.ifnum = k;
    break;
  }
}

#endif // __support_inline_h__
