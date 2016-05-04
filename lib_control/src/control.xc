// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdint.h>
#include <stddef.h>
#include "control.h"

void control_handle_message_usb(enum usb_request_direction direction,
  unsigned short windex, unsigned short wvalue, unsigned short wlength,
  uint8_t data[], size_t &?return_size, client interface control i_modules[num_modules], size_t num_modules)
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

void control_handle_message_i2c(uint8_t data[],
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

void control_handle_message_xscope(uint8_t data[],
  size_t &?return_size,
  client interface control i_modules[num_modules],
  size_t num_modules)
{
  control_handle_message_i2c(data, return_size, i_modules, num_modules);
}
