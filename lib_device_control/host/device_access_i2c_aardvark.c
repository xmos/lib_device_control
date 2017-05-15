// Copyright (c) 2017, XMOS Ltd, All rights reserved
#if USE_I2C && __APPLE__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "aardvark.h"
#include "control_host.h"
#include "control_host_support.h"

#define DBG(x) x
// #define DBG(x)

static Aardvark handle;
static AardvarkExt aaext;
static unsigned char slave_addr;

control_ret_t control_init_i2c(unsigned char i2c_slave_address)
{
  u16 ports[16];
  u32 unique_ids[16];
  int nelem = 16;
  int i;

  slave_addr = i2c_slave_address;

  // Find all attached Aardvark devices
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

  // Open the Aardvark device
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

  return CONTROL_SUCCESS;
}

static control_ret_t write_read(unsigned char data_to_send[I2C_TRANSACTION_MAX_BYTES], int data_len, 
                                unsigned char data_to_recv[I2C_TRANSACTION_MAX_BYTES], int recv_len)
{
  u16 num_bytes_sent;
  u16 num_bytes_read;
  control_ret_t ret = CONTROL_ERROR;

  int status = aa_i2c_write_read(handle, slave_addr, AA_I2C_NO_FLAGS, 
    (u16)data_len, data_to_send, &num_bytes_sent,
    (u16)recv_len, data_to_recv, &num_bytes_read);

  // Check error codes
  if ((status & 0xFF) < 0) {
    fprintf(stderr, "I2C Error while sending: %s\n", aa_status_string(status & 0xFF));
  } else if ((status & 0xFF00) < 0) {
    fprintf(stderr, "I2C Error while recieving: %s\n", aa_status_string(status & 0xFF00));
  // Check length of read/write
  } else if (num_bytes_sent == 0) {
    fprintf(stderr, "I2C Error: No bytes written. Potentially wrong slave address\n");
  } else if (num_bytes_read == 0) {
    fprintf(stderr, "I2C Error: No bytes read. \n");
  // Check all bits were sent/recieved
  } else if (num_bytes_sent != data_len) {
    fprintf(stderr, "I2C Error: Only a partial number of bytes written. %d instead of %d\n", num_bytes_sent, data_len);
  } else if (num_bytes_read != recv_len) {
    fprintf(stderr, "I2C Error: Only a partial number of bytes read. %d instead of %d\n", num_bytes_read, recv_len);
  } else {
    ret = CONTROL_SUCCESS;
  }

  return ret;
}

control_ret_t control_query_version(control_version_t *version)
{
  unsigned char data_to_send[I2C_TRANSACTION_MAX_BYTES];
  unsigned char data_to_recv[I2C_TRANSACTION_MAX_BYTES];

  int data_len = control_build_i2c_data(data_to_send, CONTROL_SPECIAL_RESID, 
    CONTROL_GET_VERSION, version, sizeof(control_version_t));

  control_ret_t ret = write_read(data_to_send, data_len, data_to_recv, sizeof(control_version_t));

  if (ret == CONTROL_SUCCESS) {
    memcpy(version, data_to_recv, sizeof(control_version_t));
    DBG(printf("Version returned: 0x%X\n", *version));
  }

  return ret;
}

control_ret_t
control_write_command(control_resid_t resid, control_cmd_t cmd,
                      const uint8_t payload[], size_t payload_len)
{
  unsigned char data_to_send[I2C_TRANSACTION_MAX_BYTES];
  int data_len = control_build_i2c_data(data_to_send, resid, cmd, payload, payload_len);
  int num_bytes_sent = aa_i2c_write(handle, slave_addr, AA_I2C_NO_FLAGS, (u16)data_len, data_to_send);

  if (num_bytes_sent < 0) {
    fprintf(stderr, "I2C Error while sending: %s\n", aa_status_string(num_bytes_sent));
  } else if (num_bytes_sent == 0) {
    fprintf(stderr, "I2C Error: No bytes written. Potentially wrong slave address\n");
  } else if (num_bytes_sent != data_len) {
    fprintf(stderr, "I2C Error: Only a partial number of bytes written. %d instead of %d\n", num_bytes_sent, data_len);
  }

  return CONTROL_SUCCESS;
}

control_ret_t
control_read_command(control_resid_t resid, control_cmd_t cmd,
                     uint8_t payload[], size_t payload_len)
{
  unsigned char data_to_send[I2C_TRANSACTION_MAX_BYTES];
  unsigned char data_to_recv[I2C_TRANSACTION_MAX_BYTES];

  int data_len = control_build_i2c_data(data_to_send, resid, cmd, payload, payload_len);
  if (data_len != 3) {
    fprintf(stderr, "Error building read command section of read_device. data_len should be 3 but is %d\n", data_len);
    return CONTROL_ERROR;
  }

  control_ret_t ret = write_read(data_to_send, data_len, data_to_recv, payload_len);

  if (ret == CONTROL_SUCCESS) {
    memcpy(payload, data_to_recv, payload_len);
  }

  return ret;
}

control_ret_t control_cleanup_i2c(void)
{
  aa_close(handle);
  return CONTROL_SUCCESS;
}

#endif // USE_I2C && __APPLE__