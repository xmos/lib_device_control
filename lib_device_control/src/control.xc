// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include "control.h"
#include "control_transport.h"
#include "resource_table.h"

#define DEBUG_CONTROL 0

void control_init(client interface control i[n], unsigned n)
{
  control_resid_t r[MAX_RESOURCES_PER_INTERFACE];
  unsigned n0;
  unsigned j;

  resource_table_init();
  for (j = 0; j < n; j++) {
    i[j].register_resources(r, n0);
    resource_table_add(r, n0, j);
  }
}

// I2C state machine
static struct {
  enum {
    I2C_IDLE,
    I2C_COMMAND,
    I2C_SIZE,
    I2C_WRITE_DATA,
    I2C_READ_DATA,
    I2C_ERROR,
  } state;
  unsigned data_so_far;
  unsigned data_expected;
  control_cmd_t cmd;
  control_resid_t resid;
  unsigned char ifnum;
  uint8_t data[I2C_MAX_BYTES];
} i2c = { I2C_IDLE, 0, 0, 0, 0, 0, {0} };

void control_process_i2c_write_transaction(uint8_t reg, uint8_t val,
                                          client interface control i[n], unsigned n)
{
#if DEBUG_CONTROL
  printf("i2c: process write transaction %d %d\n", reg, val);
#endif
  if (reg == I2C_SPECIAL_REGISTER) {
    if (val == I2C_START_COMMAND) {
      i2c.state = I2C_IDLE;
    }
    else {
#if DEBUG_CONTROL
      printf("i2c: unrecognised special command %d\n", val);
#endif
      i2c.state = I2C_ERROR;
    }
  }
  else {
    if (i2c.state == I2C_IDLE) {
      if (!resource_table_search(reg, i2c.ifnum)) {
#if DEBUG_CONTROL
        printf("i2c: resource %d not found\n", reg);
#endif
        i2c.state = I2C_ERROR;
      }
      else {
        i2c.resid = reg;
        i2c.cmd = val;
        i2c.state = I2C_COMMAND;
      }
    }
    else if (i2c.state != I2C_ERROR) {
      if (reg != i2c.resid) {
#if DEBUG_CONTROL
        printf("i2c: unexpected register %d, a command for resource %d in progress\n",
          reg, i2c.resid);
#endif
        i2c.state = I2C_ERROR;
      }
      else {
        if (i2c.state == I2C_COMMAND) {
          if (val > I2C_MAX_BYTES) {
#if DEBUG_CONTROL
            printf("i2c: length %d exceeded limit %d\n", val, I2C_MAX_BYTES);
#endif
            i2c.state = I2C_ERROR;
          }
          else {
            if (IS_CONTROL_CMD_READ(i2c.cmd)) {
              if (val == 0) {
#if DEBUG_CONTROL
                printf("i2c: %d read_command(%d, %d, %d)\n",
                  i2c.ifnum, i2c.resid, i2c.cmd, 0);
#endif
                i[i2c.ifnum].read_command(i2c.resid, i2c.cmd, i2c.data, 0);
#if DEBUG_CONTROL
                printf("i2c: read command completed\n");
#endif
                i2c.state = I2C_IDLE;
              }
              else {
#if DEBUG_CONTROL
                printf("i2c: %d read_command(%d, %d, %d)\n",
                  i2c.ifnum, i2c.resid, i2c.cmd, val);
#endif
                i[i2c.ifnum].read_command(i2c.resid, i2c.cmd, i2c.data, val);
                i2c.data_expected = val;
                i2c.data_so_far = 0;
                i2c.state = I2C_SIZE;
              }
            }
            else {
              if (val == 0) {
#if DEBUG_CONTROL
                printf("i2c: %d write_command(%d, %d, %d)\n",
                  i2c.ifnum, i2c.resid, i2c.cmd, 0);
#endif
                i[i2c.ifnum].write_command(i2c.resid, i2c.cmd, i2c.data, 0);
#if DEBUG_CONTROL
                printf("i2c: write command completed\n");
#endif
                i2c.state = I2C_IDLE;
              }
              else {
                i2c.data_expected = val;
                i2c.data_so_far = 0;
                i2c.state = I2C_SIZE;
              }
            }
          }
        }
        else if (i2c.state == I2C_SIZE || i2c.state == I2C_WRITE_DATA) {
          if (IS_CONTROL_CMD_READ(i2c.cmd)) {
#if DEBUG_CONTROL
            printf("i2c: transaction specifies data write, but a read command is in progress\n");
#endif
            i2c.state = I2C_ERROR;
          }
          else {
            i2c.data[i2c.data_so_far] = val;
            i2c.data_so_far++;
            if (i2c.data_so_far == i2c.data_expected) {
#if DEBUG_CONTROL
              printf("i2c: %d write_command(%d, %d, %d)\n",
                i2c.ifnum, i2c.resid, i2c.cmd, i2c.data_so_far);
#endif
              i[i2c.ifnum].write_command(i2c.resid, i2c.cmd, i2c.data, i2c.data_so_far);
#if DEBUG_CONTROL
              printf("i2c: write command completed\n");
#endif
              i2c.state = I2C_IDLE;
            }
            else {
              i2c.state = I2C_WRITE_DATA;
            }
          }
        }
        else if (i2c.state == I2C_READ_DATA) {
#if DEBUG_CONTROL
          printf("i2c: write transaction unexpected in read command\n");
#endif
        }
        else if (i2c.state == I2C_ERROR) {
          // silently discard transactions
        }
      }
    }
  }
}

void control_process_i2c_read_transaction(uint8_t reg, uint8_t &val,
                                         client interface control i[n], unsigned n)
{
#if DEBUG_CONTROL
  printf("i2c: process read transaction %d %d\n", reg, val);
#endif
  if (reg == I2C_SPECIAL_REGISTER) {
#if DEBUG_CONTROL
    printf("i2c: unexpected read from special register\n:");
#endif
    i2c.state = I2C_ERROR;
  }
  else if (i2c.state == I2C_SIZE || i2c.state == I2C_READ_DATA) {
    if (reg != i2c.resid) {
#if DEBUG_CONTROL
      printf("i2c: read transacition of resource %d in the middle of a command for resource %d\n",
        reg, i2c.resid);
#endif
      i2c.state = I2C_ERROR;
    }
    else if (!IS_CONTROL_CMD_READ(i2c.cmd)) {
#if DEBUG_CONTROL
      printf("i2c: read transaction unexpected with command %d which is not read\n", i2c.cmd);
#endif
      i2c.state = I2C_ERROR;
    }
    else {
      val = i2c.data[i2c.data_so_far];
      i2c.data_so_far++;
      if (i2c.data_so_far == i2c.data_expected) {
#if DEBUG_CONTROL
        printf("i2c: read command completed\n");
#endif
        i2c.state = I2C_IDLE;
      }
      else {
        i2c.state = I2C_READ_DATA;
      }
    }
  }
  else {
#if DEBUG_CONTROL
    printf("i2c: read transaction unexpected\n");
#endif
    i2c.state = I2C_ERROR;
  }
}

void control_process_usb_set_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                     const uint8_t request_data[],
                                     client interface control i[n], unsigned n)
{
  unsigned num_data_bytes;
  control_resid_t resid;
  control_cmd_t cmd;
  unsigned char ifnum;

  resid = windex;
  cmd = wvalue;
  num_data_bytes = wlength;

  if (!resource_table_search(resid, ifnum)) {
#if DEBUG_CONTROL
    printf("usb: resource %d not found\n", resid);
#endif
    return;
  }

  if (IS_CONTROL_CMD_READ(cmd)) {
#if DEBUG_CONTROL
    printf("usb: read command code %d not expected in a SET request\n", cmd);
#endif
    return;
  }

#if DEBUG_CONTROL
  printf("usb: %d(%d) %d(write) %d bytes\n", /* may be affected by bug 13373 */
    resid, ifnum, cmd, num_data_bytes);
#endif
  i[ifnum].write_command(resid, cmd, request_data, num_data_bytes);
}

void control_process_usb_get_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                     uint8_t request_data[],
                                     client interface control i[n], unsigned n)
{
  unsigned num_data_bytes;
  control_resid_t resid;
  control_cmd_t cmd;
  unsigned char ifnum;

  resid = windex;
  cmd = wvalue;
  num_data_bytes = wlength;

  if (!resource_table_search(resid, ifnum)) {
#if DEBUG_CONTROL
    printf("usb: resource %d not found\n", resid);
#endif
    return;
  }

  if (!IS_CONTROL_CMD_READ(cmd)) {
#if DEBUG_CONTROL
    printf("usb: write command code %d not expected in a GET request\n", cmd);
#endif
    return;
  }

#if DEBUG_CONTROL
  printf("usb: %d(%d) %d(read) %d bytes\n", /* may be affected by bug 13373 */
    resid, ifnum, cmd, num_data_bytes);
#endif
  i[ifnum].read_command(resid, cmd, request_data, num_data_bytes);
}

void control_process_xscope_upload(uint32_t data_in_and_out[XSCOPE_UPLOAD_MAX_WORDS],
                                   unsigned length_in, unsigned &length_out,
                                   client interface control i[n], unsigned n)
{
  struct control_xscope_packet *p;
  unsigned read_nbytes;
  unsigned char ifnum;

  p = (struct control_xscope_packet*)data_in_and_out;

  if (!resource_table_search(p->resid, ifnum)) {
#if DEBUG_CONTROL
    printf("xscope: resource %d not found\n", p->resid);
#endif
    return;
  }

  if (IS_CONTROL_CMD_READ(p->cmd)) {
    read_nbytes = p->data.read_nbytes;
    length_out = XSCOPE_HEADER_BYTES + read_nbytes;
#if DEBUG_CONTROL
    printf("xscope: %d(%d) %d(read) %d bytes\n",
      p->resid, ifnum, p->cmd, read_nbytes);
#endif
    i[ifnum].read_command(p->resid, p->cmd, p->data.read_bytes, read_nbytes);
  }
  else {
    length_out = 0;
#if DEBUG_CONTROL
    printf("xscope: %d(%d) %d(write) %d bytes\n",
      p->resid, ifnum, p->cmd, length_in - XSCOPE_HEADER_BYTES);
#endif
    i[ifnum].write_command(p->resid, p->cmd, p->data.write_bytes, length_in - XSCOPE_HEADER_BYTES);
  }
}
