// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_h__
#define __control_h__

#include <stdint.h>
#include <stddef.h>

interface control {
  void set(int address, size_t payload_size, const uint8_t payload[]);
  void get(int address, size_t payload_size, uint8_t payload[]);
};

/** Values for USB device request direction
 *  Host-to-device or device-to-host (see USB 2.0 spec 9.3)
 */
enum usb_request_direction {
  CONTROL_USB_H2D = 0,
  CONTROL_USB_D2H = 1
};

/** Handle message, USB device request transport
 *
 *  \param direction       USB device request direction
 */
void control_handle_message_usb(enum usb_request_direction direction,
  unsigned short windex,
  unsigned short wvalue,
  unsigned short wlength,
  uint8_t data[],
  size_t &?return_size,
  client interface control modules[num_modules],
  size_t num_modules);

void control_handle_message_i2c(uint8_t data[],
  size_t &?return_size,
  client interface control modules[num_modules],
  size_t num_modules);

void control_handle_message_xscope(uint8_t data[],
  size_t &?return_size,
  client interface control modules[num_modules],
  size_t num_modules);

#endif // __control_h__
