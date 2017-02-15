// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include "control.h"
#include "control_transport.h"
#include "resource_table.h"
#include <string.h>

#define DEBUG_UNIT CONTROL
#include "debug_print.h"

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
      ret += CONTROL_REGISTRATION_FAILED;
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
  if (resid == CONTROL_SPECIAL_RESID) {
    debug_printf("ignoring write to special resource %d\n", CONTROL_SPECIAL_RESID);
    return CONTROL_BAD_COMMAND;
  }
  else {
    debug_printf("%d write command %d, %d, %d\n", ifnum, resid, cmd, payload_len);
    return i[ifnum].write_command(resid, cmd, payload, payload_len);
  }
}

static control_ret_t
read_command(client interface control i[],
             unsigned char ifnum, control_resid_t resid, control_cmd_t cmd,
             uint8_t payload[], unsigned payload_len)
{
  if (resid == CONTROL_SPECIAL_RESID) {
    return special_read_command(cmd, payload, payload_len);
  }
  else {
    debug_printf("%d read command %d, %d, %d\n", ifnum, resid, cmd, payload_len);
    return i[ifnum].read_command(resid, cmd, payload, payload_len);
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

  if (i2c.state == I2C_WRITE_START) {
    if (resource_table_search(data, ifnum) != 0) {
      debug_printf("resource %d not found\n", data);
      i2c.state = I2C_ERROR;
      return CONTROL_BAD_COMMAND;
    }
    else {
      i2c.resid = data;
      i2c.ifnum = ifnum;
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
      debug_printf("length %d exceeded limit %d\n", data, I2C_DATA_MAX_BYTES);
      i2c.state = I2C_ERROR;
      return CONTROL_BAD_COMMAND;
    }
    else {
      i2c.payload_len_from_header = data;
      i2c.payload_len_transmitted = 0;
      i2c.state = I2C_WRITE_SIZE;
      if (i2c.payload_len_from_header == 0) {
        return write_command(i, i2c.ifnum, i2c.resid, i2c.cmd,
          i2c.payload, i2c.payload_len_transmitted);
      }
      else {
        return CONTROL_SUCCESS;
      }
    }
  }
  else if (i2c.state == I2C_WRITE_SIZE) {
    if (IS_CONTROL_CMD_READ(i2c.cmd)) {
      debug_printf("unexpected write data in a read command\n");
      i2c.state = I2C_ERROR;
      return CONTROL_OTHER_TRANSPORT_ERROR;
    }
    else {
      i2c.payload[0] = data;
      i2c.payload_len_transmitted = 1;
      i2c.state = I2C_WRITE_DATA;
      if (i2c.payload_len_from_header == 1) {
        return write_command(i, i2c.ifnum, i2c.resid, i2c.cmd,
          i2c.payload, i2c.payload_len_transmitted);
      }
      else {
        return CONTROL_SUCCESS;
      }
    }
  }
  else if (i2c.state == I2C_WRITE_DATA) {
    if (i2c.payload_len_transmitted == i2c.payload_len_from_header) {
      debug_printf("exceeded expected write data length %d, discarding rest of data\n",
        i2c.payload_len_from_header);
      i2c.state = I2C_WRITE_OVERFLOW;
      return CONTROL_DATA_LENGTH_ERROR;
    }
    else {
      i2c.payload[i2c.payload_len_transmitted] = data;
      i2c.payload_len_transmitted++;
      if (i2c.payload_len_transmitted == i2c.payload_len_from_header) {
        return write_command(i, i2c.ifnum, i2c.resid, i2c.cmd,
          i2c.payload, i2c.payload_len_transmitted);
      }
      else {
        return CONTROL_SUCCESS;
      }
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

  resid = windex;
  cmd = wvalue;
  payload_len = wlength;

  if (resource_table_search(resid, ifnum) != 0) {
    debug_printf("resource %d not found\n", resid);
    return CONTROL_BAD_COMMAND;
  }

  if (IS_CONTROL_CMD_READ(cmd)) {
    debug_printf("read command code %d not expected in a SET request\n", cmd);
    return CONTROL_BAD_COMMAND;
  }

  return write_command(i, ifnum, resid, cmd, request_data, payload_len);
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
    SPI_ERROR
  } state;
  control_resid_t resid;
  control_cmd_t cmd;
  unsigned char ifnum;
  unsigned payload_len_from_header;
  unsigned payload_len_transmitted;
  uint8_t payload[SPI_DATA_MAX_BYTES];
} spi = { SPI_IDLE, 0, 0, 0, 0, 0, {0} };

/* Debugging */
// static unsigned char buffer[50] = {0};
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
      ret = write_command(i_ctl, spi.ifnum, spi.resid, spi.cmd, 
                          spi.payload, spi.payload_len_transmitted);
      break;

    case SPI_READ_DATA_WAIT:
      spi.state = SPI_READ_DATA;
      reset = 0;
      break;

    default:
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
      data = spi.payload[spi.payload_len_transmitted];
      ++spi.payload_len_transmitted;
      break;

    default:
      break;
  }

  return ret;
}

/* resid, cmd, payload_len, data[0], data[1], ..., data[payload_len-1] */
/* Valid bits always assumed to be 8 */
control_ret_t
control_process_spi_master_supplied_data(uint32_t datum, uint32_t valid_bits, client interface control i_ctl[])
{ 
  /* Debugging */
  // buffer[buffer_length] = (unsigned char) datum;
  // buffer_length++;
  /*************/

  control_ret_t ret = CONTROL_SUCCESS;
  unsigned char ifnum;

  if(spi.state == SPI_READ_DATA_WAIT &&
     datum != 0) {
    /* Reset */
    memset(&spi, 0, sizeof(spi));
  }

  switch(spi.state) {
    case SPI_IDLE:
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
      spi.cmd = datum & 0x7F; /* 0111 1111 */
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
      spi.payload[spi.payload_len_transmitted] = datum;
      ++spi.payload_len_transmitted;
      break;

    default:
      break;
  }

  return ret;
}