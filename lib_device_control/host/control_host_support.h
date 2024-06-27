// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef __control_host_support_h__
#define __control_host_support_h__

#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include "control.h"
#include "control_shared.h"
#include "control_transport_shared.h"

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

#if USE_XSCOPE

static inline size_t
control_xscope_create_upload_buffer(uint32_t buffer[XSCOPE_UPLOAD_MAX_WORDS],
                                    control_cmd_t cmd, control_resid_t resid,
                                    const uint8_t *payload, unsigned payload_len)
{
  const size_t header_size = sizeof(struct control_xscope_response);
  struct control_xscope_packet *p;

  p = (struct control_xscope_packet*)buffer;

  p->resid = resid;
  p->cmd = cmd;

  assert(payload_len <= XSCOPE_DATA_MAX_BYTES && "payload length can't be represented as a uint8_t");
  p->payload_len = (uint8_t)payload_len;

  if (!IS_CONTROL_CMD_READ(cmd) && payload != NULL) {
    if (payload_len + header_size <= XSCOPE_UPLOAD_MAX_WORDS * sizeof(uint32_t)) {
      memcpy((uint8_t*)buffer + header_size, payload, payload_len);
    }
    return header_size + payload_len;
  }
  else {
    return header_size;
  }
}
#endif

#if USE_USB

static inline void
control_usb_fill_header(uint16_t *windex, uint16_t *wvalue, uint16_t *wlength,
                        control_resid_t resid, control_cmd_t cmd, unsigned payload_len)
{
  *windex = resid;
  *wvalue = cmd;

  assert(payload_len < (1<<16) && "payload length can't be represented as a uint16_t");
  *wlength = (uint16_t)payload_len;
}


#endif

#if USE_SPI

static inline size_t
control_build_spi_data(uint8_t data[SPI_TRANSACTION_MAX_BYTES],
                       control_resid_t resid, control_cmd_t cmd,
                       const uint8_t payload[], unsigned payload_len)
{
  data[0] = resid;
  data[1] = cmd;
  data[2] = (uint8_t) payload_len;

  for(unsigned i=0; i<5; ++i)
    data[3+i] = 0;

  if (IS_CONTROL_CMD_READ(cmd)) return 8;

  for(unsigned i=0; i<payload_len; ++i)
    data[3 + i] = payload[i];

  return 3 + payload_len;
}
#endif

#if USE_I2C

static inline size_t
control_build_i2c_data(uint8_t data[I2C_TRANSACTION_MAX_BYTES],
                       control_resid_t resid, control_cmd_t cmd,
                       const uint8_t payload[], unsigned payload_len)
{
  unsigned i;

  data[0] = resid;
  data[1] = cmd;
  data[2] = (uint8_t)payload_len;

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
#endif

#endif // __control_host_support_h__
