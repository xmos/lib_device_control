// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_h__
#define __control_h__

#include <stdint.h>
#include <stddef.h>

typedef uint32_t resource_id;
typedef uint8_t command_code;

#define MAX_RESOURCES_PER_INTERFACE 64

interface control {
  void register_resources(resource_id resources[MAX_RESOURCES_PER_INTERFACE],
                          unsigned &num_resources);

  void write_command(resource_id r, command_code c, const uint8_t data[n], unsigned n);

  void read_command(resource_id r, command_code c, uint8_t data[n], unsigned n);
};

void control_process_i2c_write_transaction(uint8_t reg, uint8_t val,
                                          client interface control i[n], unsigned n);

void control_process_i2c_read_transaction(uint8_t reg, uint8_t &val,
                                         client interface control i[n], unsigned n);

void control_process_usb_set_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                     const uint8_t request_data[],
                                     client interface control i[n], unsigned n);

void control_process_usb_get_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                     uint8_t request_data[],
                                     client interface control i[n], unsigned n);

/* data return is device (control library) initiated */
void control_process_xscope_upload(uint8_t data_in_and_out[],
                                   unsigned length_in, unsigned &length_out,
                                   client interface control i[n], unsigned n);

#endif // __control_h__
