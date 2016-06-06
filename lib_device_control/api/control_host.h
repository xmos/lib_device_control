// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_host_h__
#define __control_host_h__

#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>

#include "control.h"
#include "control_transport.h"

static inline size_t control_xscope_create_upload_buffer(
  uint32_t buffer[XSCOPE_UPLOAD_MAX_WORDS],
  control_cmd_t cmd, control_resid_t resid,
  const uint8_t *data, unsigned n)
{
  if (IS_CONTROL_CMD_READ(cmd)) {
    struct control_xscope_header *h;
    h = (struct control_xscope_header*)buffer;
    h->resid = resid;
    h->cmd = cmd;
    h->data_nbytes = n;
    return sizeof(struct control_xscope_header);
  }
  else {
    struct control_xscope_packet *p;
    p = (struct control_xscope_packet*)buffer;
    p->header.resid = resid;
    p->header.cmd = cmd;
    p->header.data_nbytes = n;
    if (data != NULL) {
      assert((n <= XSCOPE_DATA_MAX_BYTES) && "exceeded maximum xSCOPE payload size");
      memcpy(p->data, data, n);
    }
    return sizeof(struct control_xscope_header) + n;
  }
}

static inline void control_usb_fill_header(
  uint16_t *windex, uint16_t *wvalue, uint16_t *wlength,
  control_resid_t resid, control_cmd_t cmd, unsigned num_data_bytes)
{
  *windex = resid;
  *wvalue = cmd;

  assert(num_data_bytes < (1<<16) && "num_data_bytes can't be represented as a uint16_t");
  *wlength = (uint16_t)num_data_bytes;
}

struct i2c_transaction {
  uint8_t reg;
  uint8_t val;
};

#define I2C_SEQUENCE_LENGTH 3

static inline size_t control_build_i2c_transaction_sequence(
  struct i2c_transaction seq[I2C_SEQUENCE_LENGTH],
  control_resid_t resid, control_cmd_t cmd, unsigned num_data_bytes)
{
  seq[0].reg = I2C_SPECIAL_REGISTER;
  seq[0].val = I2C_START_COMMAND;

  seq[1].reg = resid;
  seq[1].val = cmd;

  seq[2].reg = resid;
  seq[2].val = num_data_bytes;

  return 3;
}

#endif // __control_host_h__
