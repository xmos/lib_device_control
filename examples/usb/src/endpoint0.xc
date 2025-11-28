// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <stdint.h>
#include <string.h>
#include <stdio.h>

#include <platform.h>

#include "control.h"
#include "descriptors.h"
#include "ep0_msos_descriptors.h"
#include "msos_descriptors.h"
#include "xccompat.h"
#include "xud_device.h"

/* Device Descriptor */
static unsigned char devDesc[] =
{
    0x12,                     /* 0  bLength */
    USB_DESCTYPE_DEVICE,      /* 1  bdescriptorType */
    0x01,                     /* 2  bcdUSB */
    0x02,                     /* 3  bcdUSB */
    VENDOR_SPECIFIC_CLASS,    /* 4  bDeviceClass (from xud_std_descriptors.h) */
    0,                        /* 5  bDeviceSubClass */
    0,                        /* 6  bDeviceProtocol */
    0x40,                     /* 7  bMaxPacketSize */
    (VENDOR_ID & 0xFF),       /* 8  idVendor */
    (VENDOR_ID >> 8),         /* 9  idVendor */
    (PRODUCT_ID & 0xFF),      /* 10 idProduct */
    (PRODUCT_ID >> 8),        /* 11 idProduct */
    (BCD_DEVICE & 0xFF),      /* 12 bcdDevice */
    (BCD_DEVICE >> 8),        /* 13 bcdDevice */
    MANUFACTURER_STR_INDEX,   /* 14 iManufacturer */
    PRODUCT_STR_INDEX,        /* 15 iProduct */
    0x00,                     /* 16 iSerialNumber */
    0x01                      /* 17 bNumConfigurations */
};

/* Configuration Descriptor */
static unsigned char cfgDesc[] =
{
    0x09,                           /* 0  bLength */
    USB_DESCTYPE_CONFIGURATION,     /* 1  bDescriptortype */
    0x12, 0x00,                     /* 2  wTotalLength */
    0x01,                           /* 4  bNumInterfaces */
    0x01,                           /* 5  bConfigurationValue */
    0x00,                           /* 6  iConfiguration */
    0x80,                           /* 7  bmAttributes */
    0xFA,                           /* 8  bMaxPower */

    0x09,                           /* 0  bLength */
    USB_DESCTYPE_INTERFACE,         /* 1  bDescriptorType */
    0x00,                           /* 2  bInterfaceNumber */
    0x00,                           /* 3  bAlternateSetting */
    0x00,                           /* 4: bNumEndpoints */
    VENDOR_SPECIFIC_CLASS,          /* 5: bInterfaceClass */
    VENDOR_SPECIFIC_SUBCLASS,       /* 6: bInterfaceSubClass */
    VENDOR_SPECIFIC_PROTOCOL,       /* 7: bInterfaceProtocol*/
    INTERFACE_STR_INDEX,            /* 8  iInterface */
};

unsafe {
    static char * unsafe stringDescriptors[] =
    {
        "\x09\x04",                             // Language ID string (US English)
        "XMOS",                                 // iManufacturer
        "XMOS Custom Control Device",           // iProduct
        "Custom Interface",                     // iInterface
    };
};

#define EP0_MAX_REQUEST_SIZE        256 // max allowed USB recv size
// #define EP0_MAX_REQUEST_BUF_SIZE    (EP0_MAX_REQUEST_SIZE + 2) // add 2 bytes for the CRC

static unsigned char request_data[EP0_MAX_REQUEST_SIZE] = {0};

/* Endpoint 0 Task */
void Endpoint0(chanend chan_ep0_out, chanend chan_ep0_in, client interface control i_control[1])
{
    USB_SetupPacket_t sp;
    XUD_BusSpeed_t usbBusSpeed;
    XUD_ep ep0_out = XUD_InitEp(chan_ep0_out);
    XUD_ep ep0_in  = XUD_InitEp(chan_ep0_in);

    control_init();
    control_register_resources(i_control, 1);

    while(1)
    {
        /* Returns XUD_RES_OKAY on success */
        XUD_Result_t result = USB_GetSetupPacket(ep0_out, ep0_in, sp);

        if(result == XUD_RES_OKAY)
        {
            result = XUD_RES_ERR; /* Start with error - will be set to OK if the next block is successful */
           
            unsigned bmRequestType = (sp.bmRequestType.Direction<<7) | (sp.bmRequestType.Type<<5) | (sp.bmRequestType.Recipient);
            switch(bmRequestType)
            {
                case USB_BMREQ_D2H_STANDARD_DEV:
                    if (sp.bRequest == USB_GET_DESCRIPTOR) {
                        result = Msos_Get_Bos_Descriptor(ep0_out, ep0_in, &sp);
                    }
                    break;

                case USB_BMREQ_H2D_VENDOR_DEV:
                    if (sp.wLength <= EP0_MAX_REQUEST_SIZE) {
                        size_t len_ep0 = 0;

                        XUD_Result_t loop_result = XUD_RES_OKAY;
                        while (loop_result == XUD_RES_OKAY && len_ep0 < sp.wLength) {
                            unsigned packet_len;
                            loop_result = XUD_GetBuffer(ep0_out, request_data + len_ep0, packet_len);

                            len_ep0 += packet_len;
                        }
                        result = loop_result;
                    } else {
                        result = XUD_RES_ERR;
                    }

                    if (result == XUD_RES_OKAY) {
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
                        control_ret_t ctrl = control_process_usb_set_request(sp.wIndex, sp.wValue, sp.wLength, request_data, i_control);
#pragma warning enable
                        if (ctrl == CONTROL_SUCCESS) {
                            result = XUD_DoSetRequestStatus(ep0_in);
                        }
                    }
                    break;

                case USB_BMREQ_D2H_VENDOR_DEV:
                    // printf("Msos: rqst: %d, idx: %d, val: %d, len: %d, r: %d\n", sp.bRequest, sp.wIndex, sp.wValue, sp.wLength, result);
                    if (sp.bRequest == REQUEST_GET_MS_DESCRIPTOR) {
                        result = Msos_Get_Msos_Descriptor(ep0_out, ep0_in, &sp);

                    } else {
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
                        control_ret_t ctrl = control_process_usb_get_request(sp.wIndex, sp.wValue, sp.wLength, request_data, i_control);
#pragma warning enable
                        if (ctrl == CONTROL_SUCCESS) {
                            result = XUD_DoGetRequest(ep0_out, ep0_in, request_data, sp.wLength, sp.wLength);
                        }
                    }
                    break;
            }

            /* Returns  XUD_RES_OKAY if handled okay,
             *          XUD_RES_ERR if request was not handled (i.e. STALLed),
             *          XUD_RES_UPDATE if USB Reset or suspend/resume has occurred*/
            if(result == XUD_RES_ERR)
            {
                result = USB_StandardRequests(ep0_out, ep0_in, devDesc,
                            sizeof(devDesc), cfgDesc, sizeof(cfgDesc),
                            NULL, 0,
                            NULL, 0,
                            stringDescriptors, sizeof(stringDescriptors)/sizeof(stringDescriptors[0]),
                            sp, usbBusSpeed);
            }

        }

        /* USB bus change detected, */
        if(result == XUD_RES_UPDATE)
        {
            XUD_BusState_t busState = XUD_GetBusState(ep0_out, ep0_in);

            if(busState == XUD_BUS_RESET)
            {
                /* Reset EP and get new bus speed */
                usbBusSpeed = XUD_ResetEndpoint(ep0_out, ep0_in);
            }
            else if(busState == XUD_BUS_SUSPEND)
            {
                /* Perform suspend actions */

                /* Acknowledge back to XUD letting it know we've handled suspend */
                XUD_AckBusState(ep0_out, ep0_in);
            }
            else if(busState == XUD_BUS_RESUME)
            {
                /* Perform resume actions */

                /* Acknowledge back to XUD letting it know we've handled resume */
                XUD_AckBusState(ep0_out, ep0_in);
            }
        }
    }
}
