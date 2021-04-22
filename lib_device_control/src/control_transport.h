// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef __control_transport_h__
#define __control_transport_h__

#include "control.h"

#define IS_CONTROL_CMD_READ(c) ((c) & 0x80)
#define CONTROL_CMD_SET_READ(c) ((c) | 0x80)
#define CONTROL_CMD_SET_WRITE(c) ((c) & ~0x80)

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

#define CONTROL_SPECIAL_RESID 0

#define CONTROL_GET_VERSION CONTROL_CMD_SET_READ(0)
#define CONTROL_GET_LAST_COMMAND_STATUS CONTROL_CMD_SET_READ(1)

/* The max USB packet size is 64B (USB 2.0 section 5.5.3), 
 * but larger data transfers are fragmented into several packets.
 * During testing with full speed USB it has been reported that control transfers 
 * larger than 8kB cause glitches in the audio playback, since most of the transfer 
 * time is taken by the control data, limiting the time left for the audio data.
*/
#define USB_TRANSACTION_MAX_BYTES 2048
#define USB_DATA_MAX_BYTES USB_TRANSACTION_MAX_BYTES

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
