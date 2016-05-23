// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include "xassert.h"
#include "control.h"

/* 256 entries, 8B per entry -> 2KB */
static struct resource_table_entry_t {
  control_resid_t resid;
  unsigned ifnum;
} resource_table[MAX_RESOURCES];
static unsigned resource_table_size = 0;

static void register_resources(const control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                               unsigned num_resources, unsigned ifnum)
{
  struct resource_table_entry_t *e;
  control_resid_t resid;
  unsigned i, j;

  for (i = 0; i < num_resources; i++) {
    resid = resources[i];

    for (j = 0; j < resource_table_size; j++) {
      e = &resource_table[j];
      if (e->resid == resid) {
        printf("resource 0x%X already registered on interface %d\n", resid, ifnum);
        xassert(0);
      }
    }

    if (resource_table_size >= MAX_RESOURCES) {
      printf("cannot register more than %d resources\n", resource_table_size);
      xassert(0);
    }

    e = &resource_table[resource_table_size];
    e->resid = resid;
    e->ifnum = ifnum;
    resource_table_size++;
  }
}

void control_init(client interface control i[n], unsigned n)
{
  control_resid_t r[MAX_RESOURCES_PER_INTERFACE];
  unsigned n0;
  unsigned j;

  for (j = 0; j < n; j++) {
    i[j].register_resources(r, n0);
    register_resources(r, n0, j);
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

void control_process_xscope_upload(uint8_t data_in_and_out[],
                                   unsigned length_in, unsigned &length_out,
                                   client interface control i[n], unsigned n)
{
  // TODO
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

void control_handle_message_xscope(uint8_t data[MAX_XSCOPE_PAYLOAD],
  size_t &?return_size,
  client interface control i_modules[num_modules],
  size_t num_modules)
{
  control_handle_message_i2c(data, return_size, i_modules, num_modules);
}
#endif
