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

/* host to device xSCOPE data packet
 * same format for device to host data returned over xSCOPE probe
 */
struct control_xscope_packet
{
#define XSCOPE_HEADER_BYTES 8
  control_resid_t resid;
  control_cmd_t cmd;
  uint8_t pad;
  union {
     uint8_t write_bytes[XSCOPE_UPLOAD_MAX_BYTES - XSCOPE_HEADER_BYTES];
     uint8_t read_bytes[XSCOPE_UPLOAD_MAX_BYTES - XSCOPE_HEADER_BYTES];
     unsigned read_nbytes;
  } data;
};

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
