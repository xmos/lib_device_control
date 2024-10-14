// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include "control.h"
#include "resource.h"
#include "app_device.h"

void i2c_client(server i2c_slave_callback_if i_i2c, client interface control i_control[1])
{
  control_init();
  control_register_resources(i_control, 1);
  printf("Registered");
  while (1) {
    select {
      case i_i2c.ack_write_request(void) -> i2c_slave_ack_t resp:
        if (control_process_i2c_write_start(i_control) == CONTROL_SUCCESS)
          resp = I2C_SLAVE_ACK;
        else
          resp = I2C_SLAVE_NACK;
        break;

      case i_i2c.ack_read_request(void) -> i2c_slave_ack_t resp:
        if (control_process_i2c_read_start(i_control) == CONTROL_SUCCESS)
          resp = I2C_SLAVE_ACK;
        else
          resp = I2C_SLAVE_NACK;
        break;

      case i_i2c.master_sent_data(uint8_t data) -> i2c_slave_ack_t resp:
        if (control_process_i2c_write_data(data, i_control) == CONTROL_SUCCESS)
          resp = I2C_SLAVE_ACK;
        else {
          resp = I2C_SLAVE_NACK;
        }
        break;

      case i_i2c.master_requires_data(void) -> uint8_t data:
        control_process_i2c_read_data(data, i_control);
        break;

      case i_i2c.stop_bit(void):
        control_process_i2c_stop(i_control);
        break;
    }
  }
}

void app_device(server interface control i_control)
{
  unsigned num_commands;
  int i;

  //printf("Start device app\n");
#ifdef ERRONEOUS_DEVICE
  printf("Generate errors\n");
#endif

  num_commands = 0;

  while (1) {
    select {
      case i_control.register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                                        unsigned &num_resources):
        resources[0] = RESOURCE_ID;
        num_resources = 1;
        break;

      case i_control.write_command(control_resid_t resid, control_cmd_t cmd,
                                   const uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret:
        num_commands++;
#ifdef ERRONEOUS_DEVICE
        if ((num_commands % 3) == 0)
          resid += 1;
#endif
        printf("%u: W %d %d %d,", num_commands, resid, cmd, payload_len);
        for (i = 0; i < payload_len; i++) {
          printf(" %02x", payload[i]);
        }
        printf("\n");
        if (resid != RESOURCE_ID) {
          printf("unrecognised resource ID %d\n", resid);
          ret = CONTROL_ERROR;
          break;
        }
        ret = CONTROL_SUCCESS;
        break;

      case i_control.read_command(control_resid_t resid, control_cmd_t cmd,
                                  uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret:
        num_commands++;
#ifdef ERRONEOUS_DEVICE
        if ((num_commands % 3) == 0)
          resid += 1;
#endif
        printf("%u: R %d %d %d\n", num_commands, resid, cmd, payload_len);
        if (resid != RESOURCE_ID) {
          printf("unrecognised resource ID %d\n", resid);
          ret = CONTROL_ERROR;
          break;
        }
        if (payload_len != 4) {
          printf("expecting 4 read bytes, not %d\n", payload_len);
          ret = CONTROL_ERROR;
          break;
        }
        payload[0] = 0x12;
        payload[1] = 0x34;
        payload[2] = 0x56;
        payload[3] = 0x78;
        ret = CONTROL_SUCCESS;
        break;
    }
  }
}
