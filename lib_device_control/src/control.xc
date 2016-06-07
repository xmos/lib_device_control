// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include "debug_print.h"
#include "control.h"
#include "control_transport.h"
#include "resource_table.h"

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
    I2C_WRITE_START,
    I2C_WRITE_RESID,
    I2C_WRITE_CMD,
    I2C_WRITE_SIZE,
    I2C_WRITE_DATA,
    I2C_WRITE_OVERFLOW,
    I2C_READ_START,
    I2C_READ_DATA,
    I2C_READ_OVERFLOW,
    I2C_ERROR
  } state;
  control_resid_t resid;
  control_cmd_t cmd;
  unsigned data_len_from_header;
  unsigned char ifnum;
  uint8_t data[I2C_DATA_MAX_BYTES];
  unsigned data_len_transmitted;
} i2c = { I2C_IDLE, 0, 0, 0, 0 };

control_res_t control_process_i2c_write_start(client interface control i[n], unsigned n)
{
  // always start a new command
  // that way a write start recovers us from errors
  i2c.state = I2C_WRITE_START;
  return CONTROL_SUCCESS;
}

control_res_t control_process_i2c_write_data(const uint8_t data,
                                             client interface control i[n], unsigned n)
{
  if (i2c.state == I2C_WRITE_START) {
    if (!resource_table_search(data, i2c.ifnum)) {
      debug_printf("i2c: resource %d not found\n", data);
      i2c.state = I2C_ERROR;
      return CONTROL_ERROR;
    }
    else {
      i2c.resid = data;
      i2c.state = I2C_WRITE_RESID;
      return CONTROL_SUCCESS;
    }
  }
  else if (i2c.state == I2C_WRITE_RESID) {
    i2c.cmd = data;
    i2c.state = I2C_WRITE_CMD;
    return CONTROL_SUCCESS;
  }
  else if (i2c.state == I2C_WRITE_CMD) {
    if (data > I2C_DATA_MAX_BYTES) {
      debug_printf("i2c: length %d exceeded limit %d\n", data, I2C_DATA_MAX_BYTES);
      i2c.state = I2C_ERROR;
      return CONTROL_ERROR;
    }
    else {
      i2c.data_len_from_header = data;
      i2c.data_len_transmitted = 0;
      i2c.state = I2C_WRITE_SIZE;
      return CONTROL_SUCCESS;
    }
  }
  else if (i2c.state == I2C_WRITE_SIZE) {
    if (IS_CONTROL_CMD_READ(i2c.cmd)) {
      debug_printf("i2c: unexpected write data in a read command\n");
      i2c.state = I2C_ERROR;
      return CONTROL_ERROR;
    }
    else {
      i2c.data[0] = data;
      i2c.data_len_transmitted = 1;
      i2c.state = I2C_WRITE_DATA;
      return CONTROL_SUCCESS;
    }
  }
  else if (i2c.state == I2C_WRITE_DATA) {
    if (i2c.data_len_transmitted == i2c.data_len_from_header) {
      debug_printf("i2c: exceeded expected write data length %d, discarding rest of data\n",
        i2c.data_len_from_header);
      i2c.state = I2C_WRITE_OVERFLOW;
      return CONTROL_SUCCESS;
    }
    else {
      i2c.data[i2c.data_len_transmitted] = data;
      i2c.data_len_transmitted++;
      return CONTROL_SUCCESS;
    }
  }
  else if (i2c.state == I2C_WRITE_OVERFLOW) {
    return CONTROL_SUCCESS;
  }
  else {
    i2c.state = I2C_ERROR;
    return CONTROL_ERROR;
  }
}

control_res_t control_process_i2c_read_start(client interface control i[n], unsigned n)
{
  if (i2c.state != I2C_WRITE_SIZE) {
    debug_printf("i2c: unexpected read transaction, needs to follow a correctly formed write\n");
    i2c.state = I2C_ERROR;
    return CONTROL_ERROR;
  }
  else {
    if (IS_CONTROL_CMD_READ(i2c.cmd)) {
      // assume this is a repeated start
      debug_printf("i2c: %d read_command(%d, %d, %d)\n",
        i2c.ifnum, i2c.resid, i2c.cmd, i2c.data_len_from_header);

      i[i2c.ifnum].read_command(i2c.resid, i2c.cmd, i2c.data, i2c.data_len_from_header);
      i2c.data_len_transmitted = 0;
      i2c.state = I2C_READ_START;
      return CONTROL_SUCCESS;
    }
    else {
      debug_printf("i2c: unexpected read transaction in a write command\n");
      i2c.state = I2C_ERROR;
      return CONTROL_ERROR;
    }
  }
}

control_res_t control_process_i2c_read_data(uint8_t &data,
                                            client interface control i[n], unsigned n)
{
  if (i2c.state == I2C_READ_START) {
    data = i2c.data[0];
    i2c.data_len_transmitted = 1;
    i2c.state = I2C_READ_DATA;
    return CONTROL_SUCCESS;
  }
  else if (i2c.state == I2C_READ_DATA) {
    if (i2c.data_len_transmitted == i2c.data_len_from_header) {
      debug_printf("i2c: exceeded expected read data length %d, returning zeroes now\n",
        i2c.data_len_from_header);

      i2c.state = I2C_READ_OVERFLOW;
      return CONTROL_SUCCESS;
    }
    data = i2c.data[i2c.data_len_transmitted];
    i2c.data_len_transmitted++;
    return CONTROL_SUCCESS;
  }
  else {
    i2c.state = I2C_ERROR;
    return CONTROL_ERROR;
  }
}

control_res_t control_process_i2c_stop(client interface control i[n], unsigned n)
{
  control_res_t res;
  int do_write;

  res = CONTROL_SUCCESS;
  do_write = 0;

  if (i2c.state == I2C_WRITE_SIZE) {
    if (i2c.data_len_from_header != 0) {
      debug_printf("i2c: no data written for a command with data length %d\n", i2c.data_len_from_header);
      res = CONTROL_ERROR;
    }
    else {
      do_write = 1;
      res = CONTROL_SUCCESS;
    }
  }
  else if (i2c.state == I2C_WRITE_DATA) {
    if (i2c.data_len_transmitted < i2c.data_len_from_header) {
      debug_printf("i2c: incomplete write command, %d expected, %d actual\n",
        i2c.data_len_from_header, i2c.data_len_transmitted);
      res = CONTROL_ERROR;
    }
    do_write = 1;
  }
  else if (i2c.state == I2C_WRITE_OVERFLOW) {
    debug_printf("i2c: write command with overflow\n");
    do_write = 1;
  }
  else if (i2c.state == I2C_READ_START) {
    debug_printf("i2c: read command ended with no data transaction\n");
    res = CONTROL_ERROR;
  }
  else if (i2c.state == I2C_READ_DATA) {
    if (i2c.data_len_transmitted < i2c.data_len_from_header) {
      debug_printf("i2c: incompleted read command, %d expected, %d actual\n",
        i2c.data_len_from_header, i2c.data_len_transmitted);
      res = CONTROL_ERROR;
    }
  }
  else if (i2c.state == I2C_READ_OVERFLOW) {
    debug_printf("i2c: read command with overflow\n");
  }
  else {
    i2c.state = I2C_IDLE;
    debug_printf("i2c: unexpected stop bit\n");
    return CONTROL_ERROR;
  }

  if (do_write) {
    debug_printf("i2c: %d write_command(%d, %d, %d)\n",
      i2c.ifnum, i2c.resid, i2c.cmd, i2c.data_len_transmitted);

    i[i2c.ifnum].write_command(i2c.resid, i2c.cmd, i2c.data, i2c.data_len_transmitted);
  }

  // always transition to idle after a stop bit
  i2c.state = I2C_IDLE;

  return res;
}

#if 0
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
  debug_printf("i2c: process write transaction %d %d\n", reg, val);
  if (reg == I2C_SPECIAL_REGISTER) {
    if (val == I2C_START_COMMAND) {
      i2c.state = I2C_IDLE;
    }
    else {
      debug_printf("i2c: unrecognised special command %d\n", val);
      i2c.state = I2C_ERROR;
    }
  }
  else {
    if (i2c.state == I2C_IDLE) {
      if (!resource_table_search(reg, i2c.ifnum)) {
        debug_printf("i2c: resource %d not found\n", reg);
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
        debug_printf("i2c: unexpected register %d, a command for resource %d in progress\n",
          reg, i2c.resid);
        i2c.state = I2C_ERROR;
      }
      else {
        if (i2c.state == I2C_COMMAND) {
          if (val > I2C_MAX_BYTES) {
            debug_printf("i2c: length %d exceeded limit %d\n", val, I2C_MAX_BYTES);
            i2c.state = I2C_ERROR;
          }
          else {
            if (IS_CONTROL_CMD_READ(i2c.cmd)) {
              if (val == 0) {
                debug_printf("i2c: %d read_command(%d, %d, %d)\n",
                  i2c.ifnum, i2c.resid, i2c.cmd, 0);
                i[i2c.ifnum].read_command(i2c.resid, i2c.cmd, i2c.data, 0);
                debug_printf("i2c: read command completed\n");
                i2c.state = I2C_IDLE;
              }
              else {
                debug_printf("i2c: %d read_command(%d, %d, %d)\n",
                  i2c.ifnum, i2c.resid, i2c.cmd, val);
                i[i2c.ifnum].read_command(i2c.resid, i2c.cmd, i2c.data, val);
                i2c.data_expected = val;
                i2c.data_so_far = 0;
                i2c.state = I2C_SIZE;
              }
            }
            else {
              if (val == 0) {
                debug_printf("i2c: %d write_command(%d, %d, %d)\n",
                  i2c.ifnum, i2c.resid, i2c.cmd, 0);
                i[i2c.ifnum].write_command(i2c.resid, i2c.cmd, i2c.data, 0);
                debug_printf("i2c: write command completed\n");
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
            debug_printf("i2c: transaction specifies data write, but a read command is in progress\n");
            i2c.state = I2C_ERROR;
          }
          else {
            i2c.data[i2c.data_so_far] = val;
            i2c.data_so_far++;
            if (i2c.data_so_far == i2c.data_expected) {
              debug_printf("i2c: %d write_command(%d, %d, %d)\n",
                i2c.ifnum, i2c.resid, i2c.cmd, i2c.data_so_far);
              i[i2c.ifnum].write_command(i2c.resid, i2c.cmd, i2c.data, i2c.data_so_far);
              debug_printf("i2c: write command completed\n");
              i2c.state = I2C_IDLE;
            }
            else {
              i2c.state = I2C_WRITE_DATA;
            }
          }
        }
        else if (i2c.state == I2C_READ_DATA) {
          debug_printf("i2c: write transaction unexpected in read command\n");
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
  debug_printf("i2c: process read transaction %d %d\n", reg, val);
  if (reg == I2C_SPECIAL_REGISTER) {
    debug_printf("i2c: unexpected read from special register\n:");
    i2c.state = I2C_ERROR;
  }
  else if (i2c.state == I2C_SIZE || i2c.state == I2C_READ_DATA) {
    if (reg != i2c.resid) {
      debug_printf("i2c: read transacition of resource %d in the middle of a command for resource %d\n",
        reg, i2c.resid);
      i2c.state = I2C_ERROR;
    }
    else if (!IS_CONTROL_CMD_READ(i2c.cmd)) {
      debug_printf("i2c: read transaction unexpected with command %d which is not read\n", i2c.cmd);
      i2c.state = I2C_ERROR;
    }
    else {
      val = i2c.data[i2c.data_so_far];
      i2c.data_so_far++;
      if (i2c.data_so_far == i2c.data_expected) {
        debug_printf("i2c: read command completed\n");
        i2c.state = I2C_IDLE;
      }
      else {
        i2c.state = I2C_READ_DATA;
      }
    }
  }
  else {
    debug_printf("i2c: read transaction unexpected\n");
    i2c.state = I2C_ERROR;
  }
}
#endif

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
    debug_printf("usb: resource %d not found\n", resid);
    return;
  }

  if (IS_CONTROL_CMD_READ(cmd)) {
    debug_printf("usb: read command code %d not expected in a SET request\n", cmd);
    return;
  }

  debug_printf("usb: %d(%d) %d(write) %d bytes\n", /* may be affected by bug 13373 */
    resid, ifnum, cmd, num_data_bytes);
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
    debug_printf("usb: resource %d not found\n", resid);
    return;
  }

  if (!IS_CONTROL_CMD_READ(cmd)) {
    debug_printf("usb: write command code %d not expected in a GET request\n", cmd);
    return;
  }

  debug_printf("usb: %d(%d) %d(read) %d bytes\n", /* may be affected by bug 13373 */
    resid, ifnum, cmd, num_data_bytes);
  i[ifnum].read_command(resid, cmd, request_data, num_data_bytes);
}

void control_process_xscope_upload(uint32_t data_in_and_out[XSCOPE_UPLOAD_MAX_WORDS],
                                   unsigned length_in, unsigned &length_out,
                                   client interface control i[n], unsigned n)
{
  struct control_xscope_header *h;
  struct control_xscope_packet *p;
  unsigned char ifnum;

  // use the fact that header is at start of packet
  h = (struct control_xscope_header*)data_in_and_out;
  p = (struct control_xscope_packet*)data_in_and_out;

  if (!resource_table_search(h->resid, ifnum)) {
    debug_printf("xscope: resource %d not found\n", h->resid);
    return;
  }

  if (IS_CONTROL_CMD_READ(h->cmd)) {
    length_out = sizeof(struct control_xscope_header) + h->data_nbytes;
    debug_printf("xscope: %d(%d) %d(read) %d bytes\n",
      h->resid, ifnum, h->cmd, h->data_nbytes);
    i[ifnum].read_command(h->resid, h->cmd, p->data, h->data_nbytes);
  }
  else {
    length_out = 0;
    debug_printf("xscope: %d(%d) %d(write) %d bytes\n",
      h->resid, ifnum, h->cmd, h->data_nbytes);
    i[ifnum].write_command(h->resid, h->cmd, p->data, h->data_nbytes);
  }
}
