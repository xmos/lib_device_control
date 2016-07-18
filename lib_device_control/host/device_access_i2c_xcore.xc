// Copyright (c) 2016, XMOS Ltd, All rights reserved
#if USE_I2C && __xcore__

#include <platform.h>
#include <stdio.h>
#include <stdlib.h>
#include <syscall.h>
#include <assert.h>
#include <timer.h>
#include "i2c.h"
#include "util.h"
#include "resource.h"
#include "control_host.h"
#include "control_host_support.h"

#define DEBUG_UNIT DEVICE_ACCESS
#include "debug_print.h"

static unsigned num_commands = 0;

static unsigned char slave_address = 123;

control_ret_t control_query_version(control_version_t *version,
                                    client interface i2c_master_if i_i2c)
{
  size_t num_bytes_sent;
  i2c_res_t res;
  unsigned char data[I2C_TRANSACTION_MAX_BYTES];
  size_t data_len;

  data_len = control_build_i2c_data(data, CONTROL_SPECIAL_RESID,
    CONTROL_GET_VERSION, version, sizeof(control_version_t));

  debug_printf("%u: send read command\n", num_commands);

  res = i_i2c.write(slave_address, data, data_len, num_bytes_sent, 0);

  if (res != I2C_ACK) {
    debug_printf("slave sent NAK (write transfer)\n");
    return CONTROL_ERROR;
  }
  else {
    if (num_bytes_sent != data_len) {
      debug_printf("write transfer %d bytes (%d bytes expected)\n", num_bytes_sent, data_len);
      return CONTROL_ERROR;
    }
    else {
      res = i_i2c.read(slave_address, data, sizeof(control_version_t), 1);
      if (res != I2C_ACK) {
        debug_printf("slave sent NAK (read transfer)\n");
	return CONTROL_ERROR;
      }
      else {
        memcpy(version, data, sizeof(control_version_t));
	debug_printf("version returned: 0x%X\n", *version);
      }
    }
  }

  num_commands++;

  return CONTROL_SUCCESS;
}

control_ret_t
control_write_command(control_resid_t resid, control_cmd_t cmd,
                      client interface i2c_master_if i_i2c,
                      const uint8_t payload[], size_t payload_len)
{
  size_t num_bytes_sent;
  i2c_res_t res;
  unsigned char data[I2C_TRANSACTION_MAX_BYTES];
  size_t data_len;

  data_len = control_build_i2c_data(data, resid,
    CONTROL_CMD_SET_WRITE(cmd), payload, payload_len);

  debug_printf("%u: send write command\n", num_commands);

  res = i_i2c.write(slave_address, data, data_len, num_bytes_sent, 1);

  if (res != I2C_ACK) {
    debug_printf("slave sent NAK (write transfer)\n");
    return CONTROL_ERROR;
  }
  else {
    if (num_bytes_sent != data_len) {
      debug_printf("write transfer %d bytes (%d bytes expected)\n", num_bytes_sent, data_len);
      return CONTROL_ERROR;
    }
  }

  num_commands++;

  return CONTROL_SUCCESS;
}

control_ret_t
control_read_command(control_resid_t resid, control_cmd_t cmd,
                     client interface i2c_master_if i_i2c,
                     uint8_t payload[], size_t payload_len)
{
  size_t num_bytes_sent;
  i2c_res_t res;
  unsigned char data[I2C_TRANSACTION_MAX_BYTES];
  size_t data_len;

  data_len = control_build_i2c_data(data, resid,
    CONTROL_CMD_SET_READ(cmd), payload, payload_len);

  debug_printf("%u: send read command\n", num_commands);

  res = i_i2c.write(slave_address, data, data_len, num_bytes_sent, 0);

  if (res != I2C_ACK) {
    debug_printf("slave sent NAK (write transfer)\n");
    return CONTROL_ERROR;
  }
  else {
    if (num_bytes_sent != data_len) {
      debug_printf("write transfer %d bytes (%d bytes expected)\n", num_bytes_sent, data_len);
      return CONTROL_ERROR;
    }
    else {
      res = i_i2c.read(slave_address, data, payload_len, 1);
      if (res != I2C_ACK) {
        debug_printf("slave sent NAK (read transfer)\n");
	return CONTROL_ERROR;
      }
      else {
        memcpy(payload, data, payload_len);
        debug_printf("read data returned: ");
#if DEBUG_PRINT_ENABLE_DEVICE_ACCESS
        print_bytes(payload, payload_len);
#endif
      }
    }
  }

  num_commands++;

  return CONTROL_SUCCESS;
}

control_ret_t control_init_i2c(unsigned char i2c_slave_address)
{
  slave_address = i2c_slave_address;
  return CONTROL_SUCCESS;
}

control_ret_t control_cleanup_i2c(void)
{
  return CONTROL_SUCCESS;
}

#endif // USE_I2C
