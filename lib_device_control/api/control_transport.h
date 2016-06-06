// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_transport_h__
#define __control_transport_h__

#include "control.h"

#define IS_CONTROL_CMD_READ(c) ((c) & 0x80)
#define CONTROL_CMD_SET_READ(c) ((c) | 0x80)
#define CONTROL_CMD_SET_WRITE(c) ((c) & ~0x80)

#define XSCOPE_UPLOAD_MAX_BYTES (XSCOPE_UPLOAD_MAX_WORDS * sizeof(uint32_t))
#define XSCOPE_DATA_MAX_BYTES (XSCOPE_UPLOAD_MAX_BYTES - XSCOPE_HEADER_BYTES)

struct control_xscope_packet {
#define XSCOPE_HEADER_BYTES 4
  struct control_xscope_header {
    control_resid_t resid;
    control_cmd_t cmd;
    uint8_t data_nbytes;
    uint8_t pad;
  } header;
  uint8_t data[XSCOPE_DATA_MAX_BYTES];
};

#define I2C_SPECIAL_REGISTER 0

enum control_i2c_special {
  I2C_START_COMMAND
};

#endif // __control_transport_h_
