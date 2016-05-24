// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_host_h__
#define __control_host_h__

#include <stdint.h>
#include <stddef.h>
#include <string.h>

#include "control.h"

#define IS_CONTROL_CMD_READ(c) ((c) & 0x80)
#define CONTROL_CMD_SET_READ(c) ((c) | 0x80)
#define CONTROL_CMD_SET_WRITE(c) ((c) & ~0x80)

#define XSCOPE_UPLOAD_MAX_BYTES (XSCOPE_UPLOAD_MAX_WORDS * sizeof(uint32_t))

/* xCORE is little endian */
struct control_xscope_upload
{
  control_resid_t resid;
  control_cmd_t cmd;

#define XSCOPE_HEADER_BYTES (sizeof(control_resid_t) + sizeof(control_cmd_t))

  /* can be changed if bug 17364 resolved:
   * union {
   *    uint8_t write_bytes[];
   *    unsigned read_nbytes;
   * } data;
   */
  uint8_t data[XSCOPE_UPLOAD_MAX_BYTES - XSCOPE_HEADER_BYTES];
};

struct control_xscope_probe
{
  control_resid_t resid;
  control_cmd_t cmd;
  uint8_t data[XSCOPE_UPLOAD_MAX_BYTES - XSCOPE_HEADER_BYTES];
};

static inline size_t control_create_xscope_upload_buffer(
  uint32_t buffer[XSCOPE_UPLOAD_MAX_WORDS],
  control_cmd_t c, control_res_t r,
  const uint8_t *data, unsigned n)
{
  struct control_xscope_upload *s;
  s = (struct control_xscope_upload*)buffer;

  s->resid = r;
  s->cmd = c;
  if (IS_CONTROL_CMD_READ(c)) {
    s->data[0] = n;
    s->data[1] = n >> 8;
    s->data[2] = n >> 16;
    s->data[3] = n >> 24;
  }
  else if (data != NULL) {
    memcpy(s->data, data, n);
  }

  return XSCOPE_HEADER_BYTES + n;
}

#endif // __control_host_h__
