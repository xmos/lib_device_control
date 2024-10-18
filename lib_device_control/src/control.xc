// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <xscope.h>
#include "control.h"
#include "control_transport_shared.h"
#include "resource_table.h"
#include <string.h>

#define DEBUG_UNIT CONTROL
#include "debug_print.h"
//#define debug_printf printf
control_status_t last_status;

static void debug_channel_activity(int ifnum, int value)
{
#if DEBUG_CHANNEL_ACTIVITY
  // assume probe IDs are consecutive
  int probe_id = CH_CONTROL_0 + ifnum;
  xscope_int(probe_id, value);
#endif
}

control_ret_t control_init(void)
{
  resource_table_init(CONTROL_SPECIAL_RESID);
  return CONTROL_SUCCESS;
}

control_ret_t control_register_resources(client interface control i[n], unsigned n)
{
  control_resid_t r[MAX_RESOURCES_PER_INTERFACE];
  control_ret_t ret;
  unsigned n0;
  unsigned j;

  ret = CONTROL_SUCCESS;

  for (j = 0; j < n; j++) {
    i[j].register_resources(r, n0);
    if (resource_table_add(r, n0, j) != 0)
      ret = CONTROL_REGISTRATION_FAILED;
  }

  return ret;
}

// I2C state
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
  unsigned char ifnum;
  unsigned payload_len_from_header;
  unsigned payload_len_transmitted;
  uint8_t payload[I2C_DATA_MAX_BYTES];
} i2c = { I2C_IDLE, 0, 0, 0, 0, 0, {0} };

static control_ret_t
special_read_command(control_cmd_t cmd, uint8_t payload[], unsigned payload_len)
{
  if (cmd == CONTROL_GET_VERSION) {
    debug_printf("read version\n");
    if (payload_len != sizeof(control_version_t)) {
      debug_printf("wrong payload size %d for read version command, need %d\n",
        payload_len, sizeof(control_version_t));

      return CONTROL_BAD_COMMAND;
    }
    else {
      *((control_version_t*)payload) = CONTROL_VERSION;
      return CONTROL_SUCCESS;
    }
  }
  else if (cmd == CONTROL_GET_LAST_COMMAND_STATUS) {
    debug_printf("read last command status %d\n", last_status);
    if (payload_len != sizeof(control_status_t)) {
      debug_printf("wrong payload size %d for last command status command, need %d\n",
      payload_len, sizeof(control_status_t));

      return CONTROL_BAD_COMMAND;
      }
    else {
      *((control_status_t*) payload) = last_status;
      return CONTROL_SUCCESS;
    }
  }
  else {
    debug_printf("unrecognised special resource command %d\n", cmd);
    return CONTROL_BAD_COMMAND;
  }
}

static control_ret_t
write_command(client interface control i[],
              unsigned char ifnum, control_resid_t resid, control_cmd_t cmd,
              const uint8_t payload[], unsigned payload_len)
{
  control_ret_t ret = CONTROL_ERROR;

  if (resid == CONTROL_SPECIAL_RESID) {
    debug_printf("ignoring write to special resource %d\n", CONTROL_SPECIAL_RESID);
    ret = CONTROL_BAD_COMMAND;
  }
  else {
    debug_printf("%d write command %d, %d, %d\n", ifnum, resid, cmd, payload_len);
    debug_channel_activity(ifnum, 1);
    ret = i[ifnum].write_command(resid, cmd, payload, payload_len);
    debug_channel_activity(ifnum, 0);
  }
  last_status = ret;
  return ret;
}

static control_ret_t
read_command(client interface control i[],
             unsigned char ifnum, control_resid_t resid, control_cmd_t cmd,
             uint8_t payload[], unsigned payload_len)
{
  debug_printf("Read command %d %d\n", resid, cmd);
  if (resid == CONTROL_SPECIAL_RESID) {
    return special_read_command(cmd, payload, payload_len);
  }
  else {
    debug_printf("%d read command %d, %d, %d\n", ifnum, resid, cmd, payload_len);
    debug_channel_activity(ifnum, 1);
    control_ret_t ret = i[ifnum].read_command(resid, cmd, payload, payload_len);
    debug_channel_activity(ifnum, 0);
    return ret;
  }
}

control_ret_t
control_process_i2c_write_start(client interface control i[])
{
  // always start a new command
  // that way a write start recovers us from errors
  i2c.state = I2C_WRITE_START;
  return CONTROL_SUCCESS;
}

control_ret_t
control_process_i2c_write_data(const uint8_t data, client interface control i[])
{
  unsigned char ifnum;
  control_ret_t ret = CONTROL_ERROR;

  if (i2c.state == I2C_WRITE_START) {
    if (resource_table_search(data, ifnum) != 0) {
      debug_printf("resource %d not found\n", data);
      i2c.state = I2C_ERROR;
      ret = CONTROL_BAD_COMMAND;
    }
    else {
      i2c.resid = data;
      i2c.ifnum = ifnum;
      i2c.state = I2C_WRITE_RESID;
      ret = CONTROL_SUCCESS;
    }
  }
  else if (i2c.state == I2C_WRITE_RESID) {
    i2c.cmd = data;
    i2c.state = I2C_WRITE_CMD;
    ret = CONTROL_SUCCESS;
  }
  else if (i2c.state == I2C_WRITE_CMD) {
    if (data > I2C_DATA_MAX_BYTES) {
      debug_printf("length %d exceeded limit %d\n", data, I2C_DATA_MAX_BYTES);
      i2c.state = I2C_ERROR;
      ret = CONTROL_BAD_COMMAND;
    }
    else {
      i2c.payload_len_from_header = data;
      i2c.payload_len_transmitted = 0;
      i2c.state = I2C_WRITE_SIZE;
      if (i2c.payload_len_from_header == 0) {
        ret = write_command(i, i2c.ifnum, i2c.resid, i2c.cmd,
          i2c.payload, i2c.payload_len_transmitted);
      }
      else {
        ret = CONTROL_SUCCESS;
      }
    }
  }
  else if (i2c.state == I2C_WRITE_SIZE) {
    if (IS_CONTROL_CMD_READ(i2c.cmd)) {
      debug_printf("unexpected write data in a read command\n");
      i2c.state = I2C_ERROR;
      ret = CONTROL_OTHER_TRANSPORT_ERROR;
    }
    else {
      i2c.payload[0] = data;
      i2c.payload_len_transmitted = 1;
      i2c.state = I2C_WRITE_DATA;
      if (i2c.payload_len_from_header == 1) {
        ret = write_command(i, i2c.ifnum, i2c.resid, i2c.cmd,
          i2c.payload, i2c.payload_len_transmitted);
      }
      else {
        ret = CONTROL_SUCCESS;
      }
    }
  }
  else if (i2c.state == I2C_WRITE_DATA) {
    if (i2c.payload_len_transmitted == i2c.payload_len_from_header) {
      debug_printf("exceeded expected write data length %d, discarding rest of data\n",
        i2c.payload_len_from_header);
      i2c.state = I2C_WRITE_OVERFLOW;
      ret = CONTROL_DATA_LENGTH_ERROR;
    }
    else {
      i2c.payload[i2c.payload_len_transmitted] = data;
      i2c.payload_len_transmitted++;
      if (i2c.payload_len_transmitted == i2c.payload_len_from_header) {
        ret = write_command(i, i2c.ifnum, i2c.resid, i2c.cmd,
          i2c.payload, i2c.payload_len_transmitted);
      }
      else {
        ret = CONTROL_SUCCESS;
      }
    }
  }
  else if (i2c.state == I2C_WRITE_OVERFLOW) {
    ret = CONTROL_SUCCESS;
  }
  else {
    i2c.state = I2C_ERROR;
    ret = CONTROL_ERROR;
  }
  last_status = ret;
  return ret;
}

control_ret_t
control_process_i2c_read_start(client interface control i[])
{
  control_ret_t ret;

  if (i2c.state != I2C_WRITE_SIZE) {
    debug_printf("unexpected read transaction, needs to follow a correctly formed write\n");
    i2c.state = I2C_ERROR;
    return CONTROL_OTHER_TRANSPORT_ERROR;
  }
  else {
    if (IS_CONTROL_CMD_READ(i2c.cmd)) {
      // assume this is a repeated start

      ret = read_command(i, i2c.ifnum, i2c.resid, i2c.cmd,
        i2c.payload, i2c.payload_len_from_header);

      if (ret == CONTROL_SUCCESS) {
        i2c.payload_len_transmitted = 0;
        i2c.state = I2C_READ_START;
        return CONTROL_SUCCESS;
      }
      else {
        return ret;
      }
    }
    else {
      debug_printf("unexpected read transaction in a write command\n");
      i2c.state = I2C_ERROR;
      return CONTROL_OTHER_TRANSPORT_ERROR;
    }
  }
}

control_ret_t
control_process_i2c_read_data(uint8_t &data, client interface control i[])
{
  if (i2c.state == I2C_READ_START) {
    data = i2c.payload[0];
    i2c.payload_len_transmitted = 1;
    i2c.state = I2C_READ_DATA;
    return CONTROL_SUCCESS;
  }
  else if (i2c.state == I2C_READ_DATA) {
    if (i2c.payload_len_transmitted == i2c.payload_len_from_header) {
      debug_printf("exceeded expected read data length %d, returning zeroes now\n",
        i2c.payload_len_from_header);

      i2c.state = I2C_READ_OVERFLOW;
      return CONTROL_SUCCESS;
    }
    data = i2c.payload[i2c.payload_len_transmitted];
    i2c.payload_len_transmitted++;
    return CONTROL_SUCCESS;
  }
  else {
    i2c.state = I2C_ERROR;
    return CONTROL_ERROR;
  }
}

control_ret_t
control_process_i2c_stop(client interface control i[])
{
  control_ret_t ret;

  ret = CONTROL_SUCCESS;

  if (i2c.state == I2C_WRITE_SIZE) {
    if (i2c.payload_len_from_header != 0) {
      debug_printf("no data written for a command with payload length %d\n", i2c.payload_len_from_header);
      ret = CONTROL_DATA_LENGTH_ERROR;
    }
    else {
      ret = CONTROL_SUCCESS;
    }
  }
  else if (i2c.state == I2C_WRITE_DATA) {
    if (i2c.payload_len_transmitted < i2c.payload_len_from_header) {
      debug_printf("incomplete write command, %d expected, %d actual\n",
        i2c.payload_len_from_header, i2c.payload_len_transmitted);
      ret = CONTROL_DATA_LENGTH_ERROR;
    }
  }
  else if (i2c.state == I2C_WRITE_OVERFLOW) {
    debug_printf("write command with overflow\n");
  }
  else if (i2c.state == I2C_READ_START) {
    debug_printf("read command ended with no data transaction\n");
    ret = CONTROL_OTHER_TRANSPORT_ERROR;
  }
  else if (i2c.state == I2C_READ_DATA) {
    if (i2c.payload_len_transmitted < i2c.payload_len_from_header) {
      debug_printf("incompleted read command, %d expected, %d actual\n",
        i2c.payload_len_from_header, i2c.payload_len_transmitted);
      ret = CONTROL_DATA_LENGTH_ERROR;
    }
  }
  else if (i2c.state == I2C_READ_OVERFLOW) {
    debug_printf("read command with overflow\n");
  }
  else {
    i2c.state = I2C_IDLE;
    debug_printf("unexpected stop bit\n");
    return CONTROL_OTHER_TRANSPORT_ERROR;
  }

  // always transition to idle after a stop bit
  i2c.state = I2C_IDLE;

  return ret;
}

control_ret_t
control_process_usb_set_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                const uint8_t request_data[],
                                client interface control i[])
{
  unsigned payload_len;
  control_resid_t resid;
  control_cmd_t cmd;
  unsigned char ifnum;
  control_ret_t ret = CONTROL_ERROR;

  resid = windex;
  cmd = wvalue;
  payload_len = wlength;

  if (resource_table_search(resid, ifnum) != 0) {
    debug_printf("resource %d not found\n", resid);
    ret = CONTROL_BAD_COMMAND;
  }

  if (IS_CONTROL_CMD_READ(cmd)) {
    debug_printf("read command code %d not expected in a SET request\n", cmd);
    ret = CONTROL_BAD_COMMAND;
  }
  if (ret != CONTROL_BAD_COMMAND) {
    ret = write_command(i, ifnum, resid, cmd, request_data, payload_len);
  }
  last_status = ret;
  return ret;
}

control_ret_t
control_process_usb_get_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                uint8_t request_data[],
                                client interface control i[])
{
  unsigned payload_len;
  control_resid_t resid;
  control_cmd_t cmd;
  unsigned char ifnum;

  resid = windex;
  cmd = wvalue;
  payload_len = wlength;

  if (resource_table_search(resid, ifnum) != 0) {
    debug_printf("resource %d not found\n", resid);
    return CONTROL_BAD_COMMAND;
  }

  if (!IS_CONTROL_CMD_READ(cmd)) {
    debug_printf("write command code %d not expected in a GET request\n", cmd);
    return CONTROL_BAD_COMMAND;
  }

  return read_command(i, ifnum, resid, cmd, request_data, payload_len);
}

control_ret_t
control_process_xscope_upload(uint8_t buf[], unsigned buf_size,
                              unsigned length_in, unsigned &length_out,
                              client interface control i[])
{
  struct control_xscope_packet *p;
  struct control_xscope_response *r;
  unsigned char ifnum;

  p = (struct control_xscope_packet*)buf;
  r = (struct control_xscope_response*)buf;

  length_out = sizeof(struct control_xscope_response);

  if (resource_table_search(p->resid, ifnum) != 0) {
    debug_printf("resource %d not found\n", p->resid);
    return CONTROL_BAD_COMMAND;
  }

  if (IS_CONTROL_CMD_READ(p->cmd)) {
    r->ret = read_command(i, ifnum, p->resid, p->cmd,
      buf + sizeof(struct control_xscope_response), p->payload_len);

    // only return data if user task indicated success
    if (r->ret == CONTROL_SUCCESS)
      length_out += p->payload_len;
  }
  else {
    r->ret = write_command(i, ifnum, p->resid, p->cmd,
      buf + sizeof(struct control_xscope_packet), p->payload_len);
  }

  return r->ret;
}

/* SPI state */
static struct {
  enum {
    SPI_IDLE,
    SPI_RES_RECVD,
    SPI_WRITE_CMD_RECVD,
    SPI_WRITE_DATA,
    SPI_READ_CMD_RECVD,
    SPI_READ_DATA_START,
    SPI_READ_DATA_WAIT,
    SPI_READ_DATA,
    SPI_ERROR,
    SPI_PAYLOAD_ERROR
  } state;
  control_resid_t resid;
  control_cmd_t cmd;
  unsigned char ifnum;
  unsigned payload_len_from_header;
  unsigned payload_len_transmitted;
  uint8_t payload[SPI_DATA_MAX_BYTES];
} spi = { SPI_IDLE, 0, 0, 0, 0, 0, {0} };

/* Debugging */
// static unsigned char buffer[SPI_TRANSACTION_MAX_BYTES] = {0};
// static unsigned buffer_length=0;
/************/

control_ret_t
control_process_spi_master_ends_transaction(client interface control i_ctl[])
{
  /* Debugging */
  // debug_printf("Recieved: ");
  // for(unsigned i=0; i<buffer_length; ++i)
  //   debug_printf("%u ", buffer[i]);
  // debug_printf("\n");
  // buffer_length=0;
  /*************/

  control_ret_t ret = CONTROL_SUCCESS;
  unsigned reset = 1;

  switch(spi.state) {
    case SPI_WRITE_DATA:
      if(spi.payload_len_transmitted < spi.payload_len_from_header) {
        debug_printf("Payload is less than specified in header. "
                     "Expected %d bytes; received %d bytes. Did not pass payload to program.\n",
                     spi.payload_len_from_header, spi.payload_len_transmitted);
        ret = CONTROL_ERROR;
      } else {
        ret = write_command(i_ctl, spi.ifnum, spi.resid, spi.cmd,
                            spi.payload, spi.payload_len_transmitted);
      }
      break;

    case SPI_PAYLOAD_ERROR:
      if(spi.payload_len_transmitted > spi.payload_len_from_header) {
        debug_printf("Payload is greater than specified in header. ");
      } else if (spi.payload_len_transmitted > SPI_DATA_MAX_BYTES) {
        debug_printf("Payload is greater than SPI_DATA_MAX_BYTES (%d). ", SPI_DATA_MAX_BYTES);
      }
      debug_printf("Expected %d bytes; received %d bytes. "
                   "Discarded rest of input and didn't pass payload to program.\n",
                   spi.payload_len_from_header, spi.payload_len_transmitted);
      break;

    case SPI_READ_DATA_WAIT:
      spi.state = SPI_READ_DATA;
      reset = 0;
      break;
  }

  if(reset) {
    memset(&spi, 0, sizeof(spi));
  }

  return ret;
}

control_ret_t
control_process_spi_master_requires_data(uint32_t &data, client interface control i_ctl[])
{
  control_ret_t ret = CONTROL_SUCCESS;
  data = 0;

  switch(spi.state) {
    case SPI_READ_DATA_START:
      ret = read_command(i_ctl, spi.ifnum, spi.resid, spi.cmd,
                         spi.payload, spi.payload_len_from_header);
      spi.state = SPI_READ_DATA_WAIT;
      break;

    case SPI_READ_DATA:
      if(spi.payload_len_transmitted < spi.payload_len_from_header &&
         spi.payload_len_transmitted < SPI_DATA_MAX_BYTES) {
          data = spi.payload[spi.payload_len_transmitted];
        }
        ++spi.payload_len_transmitted;
      break;
  }

  return ret;
}

control_ret_t
control_process_spi_master_supplied_data(uint32_t datum, uint32_t valid_bits, client interface control i_ctl[])
{
  /* Debugging */
  // buffer[buffer_length] = (unsigned char) datum;
  // buffer_length++;
  /*************/

  control_ret_t ret = CONTROL_SUCCESS;

  // TODO: Fix it so valid_bits need not be 8
  if(valid_bits != 8) {
    debug_printf("control_process_spi_master_supplied_data() expecting valid_bits to be 8. "
                 "Should be fed data from spi_slave using the parameter SPI_TRANSFER_SIZE_8.\n");
    return CONTROL_ERROR;
  }

  if(spi.state == SPI_READ_DATA_WAIT && datum) {
    // Reset
    memset(&spi, 0, sizeof(spi));
  }

  switch(spi.state) {
    case SPI_IDLE:
      unsigned char ifnum;
      if (resource_table_search(datum, ifnum) != 0) {
        debug_printf("Resource %d not found\n", datum);
        spi.state = SPI_ERROR;
        ret = CONTROL_ERROR;
      } else {
        spi.resid = datum;
        spi.ifnum = ifnum;
        spi.state = SPI_RES_RECVD;
      }
      break;

    case SPI_RES_RECVD:
      spi.cmd = datum;
      if(IS_CONTROL_CMD_READ(datum)) {
        spi.state = SPI_READ_CMD_RECVD;
      } else {
        spi.state = SPI_WRITE_CMD_RECVD;
      }
      break;

    case SPI_READ_CMD_RECVD:
      spi.payload_len_from_header = datum;
      spi.state = SPI_READ_DATA_START;
      break;

    case SPI_WRITE_CMD_RECVD:
      spi.payload_len_from_header = datum;
      spi.state = SPI_WRITE_DATA;
      break;

    case SPI_WRITE_DATA:
      if(spi.payload_len_transmitted < spi.payload_len_from_header &&
         spi.payload_len_transmitted < SPI_DATA_MAX_BYTES) {
        spi.payload[spi.payload_len_transmitted] = datum;
      } else {
        spi.state = SPI_PAYLOAD_ERROR;
        ret = CONTROL_ERROR;
      }
      ++spi.payload_len_transmitted;
      break;

    case SPI_PAYLOAD_ERROR:
      ++spi.payload_len_transmitted;
      break;
  }

  return ret;
}
