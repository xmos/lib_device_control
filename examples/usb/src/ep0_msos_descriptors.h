// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/** MSOS 2.0 Descriptors for vendor Endpoint 0 handling
*/

#ifndef EP0_MSOS_DESCRIPTORS
#define EP0_MSOS_DESCRIPTORS

#include <stddef.h>
#include <stdint.h>

#include "xud_device.h"

#ifdef __XC__
extern "C" {
#endif

XUD_Result_t Msos_Get_Bos_Descriptor(XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp);
XUD_Result_t Msos_Get_Msos_Descriptor(XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp);

#ifdef __XC__
} // extern "C"
#endif

#endif
