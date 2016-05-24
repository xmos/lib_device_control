// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_host_h__
#define __control_host_h__

#include <stdint.h>
#include <stddef.h>
#include <string.h>

#include "control.h"
#include "control_transport.h"

static inline size_t control_create_xscope_upload_buffer(
  uint32_t buffer[XSCOPE_UPLOAD_MAX_WORDS],
  control_cmd_t c, control_res_t r,
  const uint8_t *data, unsigned n)
{
  struct control_xscope_packet *p;
  p = (struct control_xscope_packet*)buffer;

  p->resid = r;
  p->cmd = c;
  if (IS_CONTROL_CMD_READ(c)) {
    p->data.read_nbytes = n;
  }
  else if (data != NULL) {
    memcpy(p->data.write_bytes, data, n);
  }

  return XSCOPE_HEADER_BYTES + n;
}

#endif // __control_host_h__
