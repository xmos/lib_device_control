// Copyright 2016-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef DESCRIPTORS_H
#define DESCRIPTORS_H

#include "control.h"
#include "xud_device.h"

#define EP0_MAX_PACKET_SIZE     64

#define BCD_DEVICE              0x0100
#define VENDOR_ID               0x20B1
#define PRODUCT_ID              0x001A

#define MANUFACTURER_STR_INDEX  0x01
#define PRODUCT_STR_INDEX       0x02
#define INTERFACE_STR_INDEX     0x03

/* Vendor specific class defines */
#define VENDOR_SPECIFIC_CLASS    0xff
#define VENDOR_SPECIFIC_SUBCLASS 0xff
#define VENDOR_SPECIFIC_PROTOCOL 0xff

void Endpoint0(chanend chan_ep0_out, chanend chan_ep0_in, client interface control i_control[1]);

#endif // DESCRIPTORS_H
