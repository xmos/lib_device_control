// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef __support_h__
#define __support_h__

#include "control.h"

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

void make_command(struct command &c, const struct options &o);

int check(const struct options &o,
          const struct command &c1, const struct command &c2,
          int timeout, control_ret_t ret, int num_interfaces);

void drive_user_task_registration(chanend c_user_task[n], unsigned n);

#endif // __support_h__
