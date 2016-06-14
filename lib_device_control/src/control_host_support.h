// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_host_support_h__
#define __control_host_support_h__

#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include "control.h"
#include "control_transport.h"

static inline size_t
control_xscope_create_upload_buffer(uint32_t buffer[XSCOPE_UPLOAD_MAX_WORDS],
                                    control_cmd_t cmd, control_resid_t resid,
                                    const uint8_t *payload, unsigned payload_len)
{
  struct control_xscope_packet *p;

  p = (struct control_xscope_packet*)buffer;

  if (IS_CONTROL_CMD_READ(cmd)) {
    p->resid = resid;
    p->cmd = cmd;
    p->payload_len = payload_len;
    return XSCOPE_HEADER_BYTES;
  }
  else {
    p->resid = resid;
    p->cmd = cmd;
    p->payload_len = payload_len;
    if (payload != NULL) {
      assert((payload_len <= XSCOPE_DATA_MAX_BYTES) && "exceeded maximum xSCOPE payload size");
      memcpy(p->payload, payload, payload_len);
    }
    return XSCOPE_HEADER_BYTES + payload_len;
  }
}

static inline void
control_usb_fill_header(uint16_t *windex, uint16_t *wvalue, uint16_t *wlength,
                        control_resid_t resid, control_cmd_t cmd, unsigned payload_len)
{
  *windex = resid;
  *wvalue = cmd;

  assert(payload_len < (1<<16) && "payload length can't be represented as a uint16_t");
  *wlength = (uint16_t)payload_len;
}

static inline size_t
control_build_i2c_data(uint8_t data[I2C_TRANSACTION_MAX_BYTES],
                       control_resid_t resid, control_cmd_t cmd,
                       const uint8_t payload[], unsigned payload_len)
{
  unsigned i;

  data[0] = resid;
  data[1] = cmd;
  data[2] = payload_len;

  if (IS_CONTROL_CMD_READ(cmd)) {
    return 3;
  }
  else {
    for (i = 0; i < payload_len; i++) {
      data[3 + i] = payload[i];
    }
    return 3 + payload_len;
  }
}

#endif // __control_host_support_h__
