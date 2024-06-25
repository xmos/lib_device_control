// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef __control_transport_h__
#define __control_transport_h__

#include "control.h"


struct control_xscope_packet {
  control_resid_t resid;
  control_cmd_t cmd;
  uint8_t payload_len;
  uint8_t pad;
};

struct control_xscope_response {
  control_resid_t resid;
  control_cmd_t cmd;
  uint8_t payload_len;
  control_ret_t ret;
};

// hard limit of 256 bytes for xSCOPE uploads
#define XSCOPE_UPLOAD_MAX_BYTES (XSCOPE_UPLOAD_MAX_WORDS * 4)
#define XSCOPE_UPLOAD_MAX_WORDS 64
// subtract the header size from the total upload size
#define XSCOPE_DATA_MAX_BYTES (XSCOPE_UPLOAD_MAX_BYTES - 4)

#define I2C_TRANSACTION_MAX_BYTES 256
#define I2C_DATA_MAX_BYTES (I2C_TRANSACTION_MAX_BYTES - 3)

#define SPI_TRANSACTION_MAX_BYTES 256
#define SPI_DATA_MAX_BYTES (SPI_TRANSACTION_MAX_BYTES - 3)

#endif // __control_transport_h_
