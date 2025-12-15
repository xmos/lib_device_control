// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "transport_usb.h"

#include <stdint.h>

#include "control.h"
#include "xud_device.h"

#define B_MAX_PACKET_SIZE0          64
#define EP0_MAX_REQUEST_SIZE        256 // max allowed USB recv size

static unsigned char request_data[EP0_MAX_REQUEST_SIZE] = {0};

// USB Transport device processing function, this passes USB vendor requests to the control interface.
//
// To include this file in the build, define TRANSPORT_CONFIG as "USB" in CMakeLists.txt, "set(TRANSPORT_CONFIG  "USB")"

static XUD_Result_t USB_EP0_Receive(XUD_ep ep0_out, USB_SetupPacket_t *sp, uint8_t buffer[]) {
    XUD_Result_t result = XUD_RES_OKAY;
    size_t len_ep0 = 0;
    unsigned packet_len = B_MAX_PACKET_SIZE0;

    // EP0 data handling loop. Reading in data in B_MAX_PACKET_SIZE0 chunks
    // Terminate when either we receive less than B_MAX_PACKET_SIZE0 bytes (including zero-length) or we have received the full wLength
    while ((result == XUD_RES_OKAY) && (packet_len == B_MAX_PACKET_SIZE0) && (len_ep0 < sp->wLength)) {
        result = XUD_GetBuffer(ep0_out, &buffer[len_ep0], packet_len);

        len_ep0 += packet_len;
    }
    return result;
}

// case USB_BMREQ_H2D_VENDOR_DEV:
XUD_Result_t USB_H2D_VendorRequest(XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp, client interface control i_control[]) {
    XUD_Result_t result = XUD_RES_ERR;
    if ((sp->bRequest == CONTROL_VENDOR_REQUEST) && (sp->wLength <= EP0_MAX_REQUEST_SIZE)) {
        result = USB_EP0_Receive(ep0_out, sp, request_data);

    } else {
        result = XUD_RES_ERR;
    }

    if (result == XUD_RES_OKAY) {
        control_ret_t ctrl = control_process_usb_set_request(sp->wIndex, sp->wValue, sp->wLength, request_data, i_control);
        if (ctrl == CONTROL_SUCCESS) {
            result = XUD_DoSetRequestStatus(ep0_in);
        }
    }
    return result;
}

// case USB_BMREQ_D2H_VENDOR_DEV:
XUD_Result_t USB_D2H_VendorRequest(XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp, client interface control i_control[]) {
    XUD_Result_t result = XUD_RES_ERR;
    if ((sp->bRequest == CONTROL_VENDOR_REQUEST) && (sp->wLength <= EP0_MAX_REQUEST_SIZE)) {
        control_ret_t ctrl = control_process_usb_get_request(sp->wIndex, sp->wValue, sp->wLength, request_data, i_control);
        if (ctrl == CONTROL_SUCCESS) {
            result = XUD_DoGetRequest(ep0_out, ep0_in, request_data, sp->wLength, sp->wLength);
        }
    }
    return result;
}
