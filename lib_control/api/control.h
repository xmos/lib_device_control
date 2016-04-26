// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_h__
#define __control_h__

interface control {
  void set(int address, size_t payload_size, const uint8_t payload[]);
  void get(int address, size_t payload_size, uint8_t payload[]);
};

void control_handle_message_usb(unsigned char request_direction,
  unsigned short windex, unsigned short wvalue, unsigned short wlength,
  const uint8_t request_data[], size_t received_request_data_size, size_t &return_request_data_size,
  client interface control modules[num_modules], size_t num_modules);

void control_handle_message_i2c(const uint8_t buf[], size_t received_size, size_t &return_size,
  client interface control modules[num_modules], size_t num_modules);

void control_handle_message_xscope(const uint8_t buf[], size_t received_size, size_t &return_size,
  client interface control modules[num_modules], size_t num_modules);

#endif // __wifi_h__
