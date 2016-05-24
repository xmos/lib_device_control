// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include "control.h"
#include "control_host.h"
#include "resource_table.h"

#define DEBUG 0

void control_init(client interface control i[n], unsigned n)
{
  control_resid_t r[MAX_RESOURCES_PER_INTERFACE];
  unsigned n0;
  unsigned j;

  for (j = 0; j < n; j++) {
    i[j].register_resources(r, n0);
    resource_table_register(r, n0, j);
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

void control_process_usb_set_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                     const uint8_t request_data[],
                                     client interface control i[n], unsigned n)
{
  // TODO
}

void control_process_usb_get_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                     uint8_t request_data[],
                                     client interface control i[n], unsigned n)
{
  // TODO
}

void control_process_xscope_upload(uint32_t data_in_and_out[XSCOPE_UPLOAD_MAX_WORDS],
                                   unsigned length_in, unsigned &length_out,
                                   client interface control i[n], unsigned n)
{
  struct control_xscope_upload *s;
  unsigned ifnum;

  s = (struct control_xscope_upload*)data_in_and_out;
  ifnum = resource_table_lookup(s->resid);
  if (ifnum == ~0) {
#if DEBUG
    printf("xscope: resource 0x%X not found\n", s->resid);
#endif
    return;
  }

  if (IS_CONTROL_CMD_READ(s->cmd)) {
    length_out = s->data[0] + ((unsigned)s->data[1] << 8) +
      ((unsigned)s->data[2] << 16) + ((unsigned)s->data[3] << 24);
#if DEBUG
    printf("xscope: 0x%X(%d) %d(read) %d bytes\n",
      s->resid, ifnum, s->cmd, length_out);
#endif
    i[ifnum].read_command(s->resid, s->cmd, (data_in_and_out, uint8_t[]), length_out);
  }
  else {
    length_out = 0;
#if DEBUG
    printf("xscope: 0x%X(%d) %d(write) %d bytes\n",
      s->resid, ifnum, s->cmd, length_in - XSCOPE_HEADER_BYTES);
#endif
    i[ifnum].write_command(s->resid, s->cmd, s->data, length_in - XSCOPE_HEADER_BYTES);
  }
}

#if 0
void control_handle_message_usb(enum usb_request_direction direction,
  unsigned short windex, unsigned short wvalue, unsigned short wlength,
  uint8_t data[MAX_USB_PAYLOAD], size_t &?return_size,
  client interface control i_modules[num_modules], size_t num_modules)
{
  int entity;
  int address;

  entity = windex & 0xFF;
  address = ((unsigned)(windex >> 8) << 16) | ((unsigned)(wvalue & 0xFF) << 8) | (unsigned)(wvalue >> 8);

  if (direction == CONTROL_USB_H2D) {
    if (!isnull(return_size)) {
      return_size = 0;
    }
    i_modules[entity].set(address, wlength, data);
  }
  else if (direction == CONTROL_USB_D2H) {
    if (!isnull(return_size)) {
      return_size = wlength;
    }
    i_modules[entity].get(address, wlength, data);
  }
}

enum {
  CONTROL_GET = 1,
  CONTROL_SET = 2
};

struct message {
  uint8_t direction;
  uint8_t entity;
  uint8_t address[3]; /* big endian convention */
  uint8_t payload_length;
  uint8_t payload[MAX_XSCOPE_PAYLOAD]; /* USB control request maximum, xSCOPE is probably 256 */
};

void control_handle_message_i2c(uint8_t data[MAX_I2C_PAYLOAD],
  size_t &?return_size,
  client interface control i_modules[num_modules],
  size_t num_modules)
{
  struct message *m;
  int address;

  m = (struct message*)data;
  address = ((unsigned)m->address[0] << 16) | ((unsigned)m->address[1] << 8) | (unsigned)m->address[2];

  if (m->direction == CONTROL_SET) {
    if (!isnull(return_size)) {
      return_size = 0;
    }
    i_modules[m->entity].set(address, m->payload_length, m->payload);
  }
  else if (m->direction == CONTROL_GET) {
    if (!isnull(return_size)) {
      return_size = m->payload_length;
    }
    i_modules[m->entity].get(address, m->payload_length, data);
  }
}
#endif
