// Copyright 2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef DFU_CONTROL_SERVER_H
#define DFU_CONTROL_SERVER_H

#include <xccompat.h>

#include "control.h"

/** DFU control server function
 * 
 * This links the control library to the DFU library, allowing the device to receive DFU commands over any transport
 * supported by the control library (USB, I2C, SPI, XSCOPE). Call this function from ``main()``.
 * 
 * The server registers the resource ID for DFU ``RESOURCE_ID_DFU``, then listens for read and write commands to that resource.
 * 
 * \param dfu_control_interface The control interface to use for connection to the transport.
 */
void dfu_control_server(SERVER_INTERFACE(control, dfu_control_interface));

#endif // DFU_CONTROL_SERVER_H
