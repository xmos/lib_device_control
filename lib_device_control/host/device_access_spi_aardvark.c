// Copyright (c) 2017, XMOS Ltd, All rights reserved
#if USE_SPI && __APPLE__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "aardvark.h"
#include "control_host.h"
#include "control_host_support.h"
#include "unistd.h"

// #define DBG(x) x
#define DBG(x)

static Aardvark handle;
static unsigned delay_milliseconds;

static int lib_spi_to_ardvark_mode(spi_mode_t spi_mode)
{
  if(spi_mode == SPI_MODE_0) return 1;
  else if(spi_mode == SPI_MODE_1) return 0;
  else if(spi_mode == SPI_MODE_2) return 2;
  else return 3;
}

control_ret_t control_init_spi(spi_mode_t spi_mode, int spi_bitrate, unsigned delay_for_read)
{
  AardvarkExt aaext;
  u16 ports[16];
  u32 unique_ids[16];
  int nelem = 16;
  int i;

  int mode = lib_spi_to_ardvark_mode(spi_mode);
  delay_milliseconds = delay_for_read;

  /* Find all attached Aardvark devices */
  int count = aa_find_devices_ext(nelem, ports, nelem, unique_ids);

  if(count > 0) {
    DBG(printf("Found %d Aardvark device(s). Using first available\n", count));
  } else {
    fprintf(stderr, "Could not find any Aardvark devices\n");
    return 1;
  }

  if (count > nelem)  count = nelem;
  for(i=0; i<count; ++i) {
    if (!(ports[i] & AA_PORT_NOT_FREE)) {
      break;
    }
  }

  /* Open the Aardvark device */
  if(i != count) {
    handle = aa_open_ext(ports[i], &aaext);
  } else {
    fprintf(stderr, "Unable to open device\n");
    return 1;
  }

  if (handle <= 0) {
    fprintf(stderr, "Unable to open Aardvark device on port %d\n", ports[i]);
    fprintf(stderr, "Error code = %d\n", handle);
    return 1;
  }

  DBG(printf("Opened Aardvark adapter; features = 0x%02x\n", aaext.features));

  /* Ensure that the SPI subsystem is enabled */
  aa_configure(handle, AA_CONFIG_SPI_I2C);

  /* Setup the clock phase */
  aa_spi_configure(handle, mode >> 1, mode & 1, AA_SPI_BITORDER_MSB);

  /* Setup the bitrate */
  int bitrate = aa_spi_bitrate(handle, spi_bitrate);
  #pragma unused(bitrate)
  DBG(printf("Bitrate set to %d kHz\n", bitrate));

  return CONTROL_SUCCESS;
}

control_ret_t
control_write_command(control_resid_t resid, control_cmd_t cmd,
                      const uint8_t payload[], size_t payload_len)
{
  control_ret_t ret = CONTROL_ERROR;
  uint8_t data_to_send[SPI_TRANSACTION_MAX_BYTES];
  uint8_t data_recieved[SPI_TRANSACTION_MAX_BYTES];

  int data_len = control_build_spi_data(data_to_send, resid, cmd, payload, payload_len);
  int num_bytes_sent = aa_spi_write(handle, (u16)data_len, data_to_send, (u16)data_len, data_recieved);

  if (num_bytes_sent < 0) {
    fprintf(stderr, "SPI Error while sending: %s\n", aa_status_string(num_bytes_sent));
  } else if (num_bytes_sent == 0) {
    fprintf(stderr, "SPI Error: No bytes written. Potentially wrong slave address\n");
  } else if (num_bytes_sent != data_len) {
    fprintf(stderr, "SPI Error: Only a partial number of bytes written. %d instead of %d\n", num_bytes_sent, data_len);
  } else {
    ret = CONTROL_SUCCESS;
  }

  return ret;
}

control_ret_t
control_read_command(control_resid_t resid, control_cmd_t cmd,
                     uint8_t payload[], size_t payload_len)
{
  control_ret_t ret = CONTROL_ERROR;
  uint8_t data_to_send[SPI_TRANSACTION_MAX_BYTES] = {0};
  uint8_t data_recieved[SPI_TRANSACTION_MAX_BYTES] = {0};

  int data_len = control_build_spi_data(data_to_send, resid, cmd, payload, payload_len);
  if (data_len != 8) {
    fprintf(stderr, "Error building read command section of read_device. data_len should be 8 but is %d\n", data_len);
    return CONTROL_ERROR;
  }

  int num_bytes_sent = aa_spi_write(handle, (u16)data_len, data_to_send, (u16)data_len, data_recieved);

  memset(data_to_send, 0, SPI_TRANSACTION_MAX_BYTES);
  memset(data_recieved, 0, SPI_TRANSACTION_MAX_BYTES);

  unsigned transaction_length = payload_len < 8 ? 8 : payload_len;

  usleep(delay_milliseconds * 1000);
  aa_spi_write(handle, (u16)transaction_length, data_to_send, (u16)transaction_length, data_recieved);
  DBG(printf("Data recieved: "));
  for(unsigned i=0; i<transaction_length; ++i) {
    DBG(printf("%-3d ", data_recieved[i]));
  }

  if (num_bytes_sent < 0) {
    fprintf(stderr, "SPI Error while sending: %s\n", aa_status_string(num_bytes_sent));
  } else if (num_bytes_sent == 0) {
    fprintf(stderr, "SPI Error: No bytes written. Potentially wrong slave address\n");
  } else if (num_bytes_sent != data_len) {
    fprintf(stderr, "SPI Error: Only a partial number of bytes written. %d instead of %d\n", num_bytes_sent, data_len);
  } else {
    memcpy(payload, data_recieved, payload_len);
    ret = CONTROL_SUCCESS;
  }

  return ret;
}

control_ret_t control_cleanup_spi(void)
{
  aa_close(handle);
  return CONTROL_SUCCESS;
}

#endif // USE_SPI && __APPLE__