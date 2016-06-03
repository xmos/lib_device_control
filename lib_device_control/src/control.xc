// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include "control.h"
#include "control_transport.h"
#include "resource_table.h"

#define DEBUG 0

void control_init(client interface control i[n], unsigned n)
{
  control_resid_t r[MAX_RESOURCES_PER_INTERFACE];
  unsigned n0;
  unsigned j;

  for (j = 0; j < n; j++) {
    i[j].register_resources(r, n0);
    resource_table_add(r, n0, j);
  }
}

void control_process_i2c_write_transaction(uint8_t reg, uint8_t val,
                                          client interface control i[n], unsigned n)
{
  // TODO
}

void control_process_i2c_read_transaction(uint8_t reg, uint8_t &val,
                                         client interface control i[n], unsigned n)
{
  // TODO
}

void control_process_usb_ep0_set_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                         const uint8_t request_data[],
                                         client interface control i[n], unsigned n)
{
  control_idx_t idx;
  unsigned num_data_bytes;
  control_resid_t resid;
  control_cmd_t cmd;
  unsigned ifnum;

  idx = windex;
  cmd = wvalue;
  num_data_bytes = wlength;

  if (!resource_table_find_index(idx, resid, ifnum)) {
#if DEBUG
    printf("usb_ep0: resource index 0x%X not found\n", idx);
#endif
    return;
  }

  if (IS_CONTROL_CMD_READ(cmd)) {
#if DEBUG
    printf("usb_ep0: read command code %d not expected in a SET request\n", cmd);
#endif
    return;
  }

#if DEBUG
  printf("usb_ep0: 0x%X(%d) %d(write) %d bytes\n",
    resid, ifnum, cmd, num_data_bytes);
#endif
  i[ifnum].write_command(resid, cmd, request_data, num_data_bytes);
}

void control_process_usb_ep0_get_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                         uint8_t request_data[],
                                         client interface control i[n], unsigned n)
{
  control_idx_t idx;
  unsigned num_data_bytes;
  control_resid_t resid;
  control_cmd_t cmd;
  unsigned ifnum;

  idx = windex;
  cmd = wvalue;
  num_data_bytes = wlength;

  if (!resource_table_find_index(idx, resid, ifnum)) {
#if DEBUG
    printf("usb_ep0: resource index 0x%X not found\n", idx);
#endif
    return;
  }

  if (!IS_CONTROL_CMD_READ(cmd)) {
#if DEBUG
    printf("usb_ep0: write command code %d not expected in a GET request\n", cmd);
#endif
    return;
  }

#if DEBUG
  printf("usb_ep0: 0x%X(%d) %d(read) %d bytes\n",
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
  unsigned ifnum;

  p = (struct control_xscope_packet*)data_in_and_out;

  if (!resource_table_find_resid(p->resid, ifnum)) {
#if DEBUG
    printf("xscope: resource 0x%X not found\n", p->resid);
#endif
    return;
  }

  if (IS_CONTROL_CMD_READ(p->cmd)) {
    read_nbytes = p->data.read_nbytes;
    length_out = XSCOPE_HEADER_BYTES + read_nbytes;
#if DEBUG
    printf("xscope: 0x%X(%d) %d(read) %d bytes\n",
      p->resid, ifnum, p->cmd, read_nbytes);
#endif
    i[ifnum].read_command(p->resid, p->cmd, p->data.read_bytes, read_nbytes);
  }
  else {
    length_out = 0;
#if DEBUG
    printf("xscope: 0x%X(%d) %d(write) %d bytes\n",
      p->resid, ifnum, p->cmd, length_in - XSCOPE_HEADER_BYTES);
#endif
    i[ifnum].write_command(p->resid, p->cmd, p->data.write_bytes, length_in - XSCOPE_HEADER_BYTES);
  }
}
