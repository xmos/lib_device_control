// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <platform.h>
#include <assert.h>
#include <xscope.h>
#include <stdio.h>
#include <stdint.h>
#include "debug_print.h"
#include "usb.h"
#include "hid.h"
#include "descriptors.h"
#include "control.h"
#include "app.h"

void endpoint0(chanend c_ep0_out, chanend c_ep0_in, client interface control i_control[1])
{
  USB_SetupPacket_t sp;
  XUD_Result_t res;
  XUD_BusSpeed_t bus_speed;
  XUD_ep ep0_out, ep0_in;
  unsigned short descriptor_type;
  unsigned char zero_hid_report[] = {0, 0, 0, 0};
  unsigned char request_data[EP0_MAX_PACKET_SIZE];
  size_t len;

  ep0_out = XUD_InitEp(c_ep0_out, XUD_EPTYPE_CTL | XUD_STATUS_ENABLE);
  ep0_in = XUD_InitEp(c_ep0_in, XUD_EPTYPE_CTL | XUD_STATUS_ENABLE);

  control_init(i_control, 1);

  while (1) {
    res = USB_GetSetupPacket(ep0_out, ep0_in, sp);

    if (res == XUD_RES_OKAY) {
      /* set result to ERR, we expect it to get set to OKAY if a request is handled */
      res = XUD_RES_ERR;

      switch ((sp.bmRequestType.Direction << 7) | (sp.bmRequestType.Type << 5) | (sp.bmRequestType.Recipient)) {
        case USB_BMREQ_H2D_STANDARD_DEV:
        if (sp.bRequest == USB_SET_ADDRESS) {
          debug_printf("enumerated (address %d)\n", sp.wValue);
        }
        break;

        case USB_BMREQ_D2H_STANDARD_INT:
          if (sp.bRequest == USB_GET_DESCRIPTOR) {
          if (sp.wIndex == HID_INTERFACE_NUM) {
            descriptor_type = sp.wValue & 0xFF00;
            switch (descriptor_type) {
            case HID_HID:
              res = XUD_DoGetRequest(ep0_out, ep0_in, hid_descriptor, sizeof(hid_descriptor), sp.wLength);
              break;

            case HID_REPORT:
              res = XUD_DoGetRequest(ep0_out, ep0_in, hid_report_descriptor, sizeof(hid_report_descriptor), sp.wLength);
              break;
            }
          }
        }
        break;

        case USB_BMREQ_H2D_CLASS_INT:
        case USB_BMREQ_D2H_CLASS_INT:
          if (sp.wIndex == HID_INTERFACE_NUM) {
            if (sp.bRequest == HID_GET_REPORT) { /* ok to stall all other HID class requests */
              res = XUD_DoGetRequest(ep0_out, ep0_in, zero_hid_report, 4, sp.wLength);
            }
          }
          break;
        
        case USB_BMREQ_H2D_VENDOR_DEV:
          res = XUD_GetBuffer(ep0_out, request_data, len);
          if (res == XUD_RES_OKAY) {
            control_process_usb_ep0_set_request(sp.wIndex, sp.wValue, sp.wLength, request_data, i_control, 1);
            res = XUD_DoSetRequestStatus(ep0_in);
          }
          break;

        case USB_BMREQ_D2H_VENDOR_DEV:
          /* application retrieval latency inside the control library call
           * XUD task defers further calls by NAKing USB transactions
           */
          control_process_usb_ep0_get_request(sp.wIndex, sp.wValue, sp.wLength, request_data, i_control, 1);
          len = sp.wLength;
          res = XUD_DoGetRequest(ep0_out, ep0_in, request_data, len, len);
          break;
      }
    }

    if (res == XUD_RES_ERR) {
      /* if we haven't handled the request about then do standard enumeration requests */
      unsafe {
        res = USB_StandardRequests(ep0_out, ep0_in, device_descriptor,
          sizeof(device_descriptor), configuration_descriptor, sizeof(configuration_descriptor),
          null, 0, null, 0,
          string_descriptors, sizeof(string_descriptors) / sizeof(string_descriptors[0]),
          sp, bus_speed);
      }
    }

    if (res == XUD_RES_RST) {
      bus_speed = XUD_ResetEndpoint(ep0_out, ep0_in);
    }
  }
}

void hid_endpoint(chanend c_ep_hid)
{
  unsigned char zero_hid_report[] = {0, 0, 0, 0};
  XUD_ep ep = XUD_InitEp(c_ep_hid, XUD_EPTYPE_BUL);
  XUD_SetBuffer(ep, zero_hid_report, 4);
}

enum {
  EP_OUT_ZERO,
  NUM_EP_OUT
};

enum {
  EP_IN_ZERO,
  EP_IN_HID,
  NUM_EP_IN
};

int main(void)
{
  chan c_ep_out[NUM_EP_OUT], c_ep_in[NUM_EP_IN];
  interface control i_control[1];
  par {
    on USB_TILE: par {
      app(i_control[0]);
      hid_endpoint(c_ep_in[1]);
      endpoint0(c_ep_out[0], c_ep_in[0], i_control);
      xud(c_ep_out, NUM_EP_OUT, c_ep_in, NUM_EP_IN, null, XUD_SPEED_HS, XUD_PWR_SELF);
    }
  }
  return 0;
}
