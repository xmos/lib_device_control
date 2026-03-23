// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef TRANSPORT_USB_H
#define TRANSPORT_USB_H

#include <xccompat.h>

#include "control.h"
#include "xud_device.h"

/** USB transport host write (Set) processing function
 * 
 * This function handles USB vendor requests from the host to the device.
 * It should be called from the Endpoint 0 thread of the application, in the case where CONTROL_USE_USB is defined as 1.
 * The function receives the host data and passes it to the control interface for handling the request.
 * 
 * \param ep0_out  Endpoint 0 OUT endpoint
 * \param ep0_in   Endpoint 0 IN endpoint
 * \param sp       Pointer to USB setup packet
 * \param i_control  Control interface array
 * 
 * \return XUD_Result_t Result of the operation
 */
XUD_Result_t USB_H2D_VendorRequest(XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp, CLIENT_INTERFACE(control, i_control[]));

/** USB transport host read (Get) processing function
 * 
 * This function handles USB vendor requests from the device to the host.
 * It should be called from the Endpoint 0 thread of the application, in the case where CONTROL_USE_USB is defined as 1.
 * The function calls the control interface for handling the request, and sends data back to the host as needed.
 * 
 * \param ep0_out  Endpoint 0 OUT endpoint
 * \param ep0_in   Endpoint 0 IN endpoint
 * \param sp       Pointer to USB setup packet
 * \param i_control  Control interface array
 * 
 * \return XUD_Result_t Result of the operation
 */
XUD_Result_t USB_D2H_VendorRequest(XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp, CLIENT_INTERFACE(control, i_control[]));

#endif // TRANSPORT_USB_H
