// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_transport_h__
#define __control_transport_h__

#include "control.h"

typedef uint8_t control_resid_hash_t;

#define IS_CONTROL_CMD_READ(c) ((c) & 0x80)
#define CONTROL_CMD_SET_READ(c) ((c) | 0x80)
#define CONTROL_CMD_SET_WRITE(c) ((c) & ~0x80)

#define XSCOPE_UPLOAD_MAX_BYTES (XSCOPE_UPLOAD_MAX_WORDS * sizeof(uint32_t))

/* xCORE is little endian */

/* host to device xSCOPE data packet
 * same format for device to host data returned over xSCOPE probe
 */
struct control_xscope_packet {
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

#endif // __control_transport_h_
