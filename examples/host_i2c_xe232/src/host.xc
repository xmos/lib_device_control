// Copyright (c) 2016, XMOS Ltd, All rights reserved
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

port p_scl = on tile[0]: XS1_PORT_1E; /* XE232 board J5 pin 13 */
port p_sda = on tile[0]: XS1_PORT_1F; /* J5 pin 14 */
                                      /* ground J5 pins 8 and 16 */
static void pause_short()
{
  delay_milliseconds(100);
}

static void pause_long()
{
  delay_milliseconds(1000);
}

unsigned num_commands = 0;

const char device_addr = 123;

void do_version_command(client interface i2c_master_if i_i2c)
{
  control_version_t version;
  size_t num_bytes_sent;
  i2c_res_t res;
  unsigned char data[I2C_TRANSACTION_MAX_BYTES];
  size_t data_len;

  data_len = control_build_i2c_data(data, CONTROL_SPECIAL_RESID,
    CONTROL_GET_VERSION, &version, sizeof(control_version_t));

  printf("%u: send read command\n", num_commands);

  res = i_i2c.write(device_addr, data, data_len, num_bytes_sent, 0);

  if (res != I2C_ACK) {
    printf("slave sent NAK (write transfer)\n");
  }
  else {
    if (num_bytes_sent != data_len) {
      printf("write transfer %d bytes (%d bytes expected)\n",
        num_bytes_sent, data_len);
    }
    else {
      res = i_i2c.read(device_addr, data, sizeof(control_version_t), 1);
      if (res != I2C_ACK) {
        printf("slave sent NAK (read transfer)\n");
      }
      else {
        memcpy(&version, data, sizeof(control_version_t));
        printf("version returned: 0x%X\n", version);
      }
    }
  }

  num_commands++;
}

void do_write_command(client interface i2c_master_if i_i2c)
{
  unsigned char payload[1];
  size_t num_bytes_sent;
  i2c_res_t res;
  unsigned char data[I2C_TRANSACTION_MAX_BYTES];
  size_t data_len;

  payload[0] = 1;
  data_len = control_build_i2c_data(data, RESOURCE_ID,
    CONTROL_CMD_SET_WRITE(0), payload, sizeof(payload));

  printf("%u: send write command\n", num_commands);

  res = i_i2c.write(device_addr, data, data_len, num_bytes_sent, 1);

  if (res != I2C_ACK) {
    printf("slave sent NAK (write transfer)\n");
  }
  else {
    if (num_bytes_sent != data_len) {
      printf("write transfer %d bytes (%d bytes expected)\n",
        num_bytes_sent, data_len);
    }
  }

  num_commands++;
}

void do_read_command(client interface i2c_master_if i_i2c)
{
  unsigned char payload[4];
  size_t num_bytes_sent;
  i2c_res_t res;
  unsigned char data[I2C_TRANSACTION_MAX_BYTES];
  size_t data_len;

  data_len = control_build_i2c_data(data, RESOURCE_ID,
    CONTROL_CMD_SET_READ(0), payload, sizeof(payload));

  printf("%u: send read command\n", num_commands);

  res = i_i2c.write(device_addr, data, data_len, num_bytes_sent, 0);

  if (res != I2C_ACK) {
    printf("slave sent NAK (write transfer)\n");
  }
  else {
    if (num_bytes_sent != data_len) {
      printf("write transfer %d bytes (%d bytes expected)\n",
        num_bytes_sent, data_len);
    }
    else {
      res = i_i2c.read(device_addr, data, sizeof(payload), 1);
      if (res != I2C_ACK) {
        printf("slave sent NAK (read transfer)\n");
      }
      else {
        memcpy(payload, data, sizeof(payload));
        printf("read data returned: ");
        print_bytes(payload, sizeof(payload));
      }
    }
  }

  num_commands++;
}

void app(client interface i2c_master_if i_i2c)
{
  int i;

  printf("started\n");
  printf("device address %d\n", device_addr);

  do_version_command(i_i2c);

  while (1) {
    for (i = 0; i < 4; i++) {
      do_write_command(i_i2c);
      pause_short();
      do_read_command(i_i2c);
      pause_long();
    }
  }
}

int main(void)
{
  i2c_master_if i_i2c[1];
  par {
    on tile[0]: i2c_master(i_i2c, 1, p_scl, p_sda, 200);
    on tile[1]: app(i_i2c[0]);
  }
  return 0;
}
