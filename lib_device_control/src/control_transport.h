// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_transport_h__
#define __control_transport_h__

#include "control.h"

#define IS_CONTROL_CMD_READ(c) ((c) & 0x80)
#define CONTROL_CMD_SET_READ(c) ((c) | 0x80)
#define CONTROL_CMD_SET_WRITE(c) ((c) & ~0x80)

#define XSCOPE_UPLOAD_MAX_BYTES (XSCOPE_UPLOAD_MAX_WORDS * sizeof(uint32_t))
#define XSCOPE_DATA_MAX_BYTES (XSCOPE_UPLOAD_MAX_BYTES - XSCOPE_HEADER_BYTES)

#define I2C_TRANSACTION_MAX_BYTES 256
#define I2C_DATA_MAX_BYTES (I2C_TRANSACTION_MAX_BYTES - 3)

#define XSCOPE_HEADER_BYTES 4

struct control_xscope_packet {
  control_resid_t resid;
  control_cmd_t cmd;
  uint8_t payload_len;
  uint8_t pad;
  uint8_t payload[XSCOPE_DATA_MAX_BYTES];
};

struct control_xscope_response {
  control_resid_t resid;
  control_cmd_t cmd;
  uint8_t payload_len;
  control_ret_t ret;
  uint8_t payload[XSCOPE_DATA_MAX_BYTES];
};

#define CONTROL_SPECIAL_RESID 0

#define CONTROL_GET_VERSION CONTROL_CMD_SET_READ(0)
#define CONTROL_GET_LAST_COMMAND_STATUS CONTROL_CMD_SET_READ(1)

#endif // __control_transport_h_
