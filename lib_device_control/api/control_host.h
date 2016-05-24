// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_host_h__
#define __control_host_h__

#include <stdint.h>
#include <stddef.h>
#include <string.h>

#include "control.h"
#include "control_transport.h"

static inline size_t control_xscope_create_upload_buffer(
  uint32_t buffer[XSCOPE_UPLOAD_MAX_WORDS],
  control_cmd_t cmd, control_res_t resid,
  const uint8_t *data, unsigned n)
{
  struct control_xscope_packet *p;
  p = (struct control_xscope_packet*)buffer;

  p->resid = resid;
  p->cmd = cmd;
  if (IS_CONTROL_CMD_READ(cmd)) {
    p->data.read_nbytes = n;
  }
  else if (data != NULL) {
    memcpy(p->data.write_bytes, data, n);
  }

  return XSCOPE_HEADER_BYTES + n;
}

static inline void control_usb_ep0_fill_header(
  uint16_t *windex, uint16_t *wvalue, uint16_t *wlength,
  control_resid_hash_t hash, control_cmd_t cmd, unsigned num_data_bytes)
{
  *windex = hash;
  *wvalue = cmd;
  *wlength = num_data_bytes;
}

#endif // __control_host_h__
