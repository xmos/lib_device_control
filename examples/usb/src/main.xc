// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "xud_device.h"
#include <platform.h>
#include <assert.h>
#include <xscope.h>
#include <stdio.h>
#include <stdint.h>
#include "descriptors.h"
#include "control.h"
#include "app.h"

#define DEBUG_UNIT DEVICE
#include "debug_print.h"

void endpoint0(chanend c_ep0_out, chanend c_ep0_in, client interface control i_control[1])
{
  USB_SetupPacket_t sp;
  XUD_Result_t res;
  XUD_BusSpeed_t bus_speed;
  XUD_ep ep0_out, ep0_in;
  unsigned char request_data[EP0_MAX_PACKET_SIZE];
  int handled;
  size_t len;

  ep0_out = XUD_InitEp(c_ep0_out);
  ep0_in = XUD_InitEp(c_ep0_in);

  control_init();
  control_register_resources(i_control, 1);

  while (1) {
    res = USB_GetSetupPacket(ep0_out, ep0_in, sp);
    handled = 0;

    if (res == XUD_RES_OKAY) {

      debug_printf("recipient %d type %d direction %d request %d value %d index %d length %d\n",
        sp.bmRequestType.Recipient, sp.bmRequestType.Type, sp.bmRequestType.Direction,
        sp.bRequest, sp.wValue, sp.wIndex, sp.wLength);

      switch ((sp.bmRequestType.Direction << 7) | (sp.bmRequestType.Type << 5) | (sp.bmRequestType.Recipient)) {

        case USB_BMREQ_H2D_VENDOR_DEV:
          res = XUD_GetBuffer(ep0_out, request_data, len);
          if (res == XUD_RES_OKAY) {
            if (control_process_usb_set_request(sp.wIndex, sp.wValue, sp.wLength,
                                                request_data, i_control) == CONTROL_SUCCESS) {
              /* zero length data to indicate success
               * on control error, go to standard requests, which will issue STALL
               */
              res = XUD_DoSetRequestStatus(ep0_in);
              handled = 1;
            }
          }
          break;

        case USB_BMREQ_D2H_VENDOR_DEV:
          /* application retrieval latency inside the control library call
           * XUD task defers further calls by NAKing USB transactions
           */
          if (control_process_usb_get_request(sp.wIndex, sp.wValue, sp.wLength,
                                              request_data, i_control) == CONTROL_SUCCESS) {
            len = sp.wLength;
            res = XUD_DoGetRequest(ep0_out, ep0_in, request_data, len, len);
            handled = 1;
            /* on control error, go to standard requests, which will issue STALL */
          }
          break;
      }

      if (!handled) {
        /* if we haven't handled the request about then do standard enumeration requests */
        debug_printf("not handled, passing to standard requests\n");
        unsafe {
          res = USB_StandardRequests(ep0_out, ep0_in, devDesc,
            sizeof(devDesc), cfgDesc, sizeof(cfgDesc),
            null, 0, null, 0,
            stringDescriptors, sizeof(stringDescriptors) / sizeof(stringDescriptors[0]),
            sp, bus_speed);
        }
      }
    }

    if (res == XUD_RES_RST) {
      bus_speed = XUD_ResetEndpoint(ep0_out, ep0_in);
    }
  }
}

/* USB Endpoint Defines */
#define XUD_EP_COUNT_OUT   1    //Includes EP0 (1 OUT EP0)
#define XUD_EP_COUNT_IN    1    //Includes EP0 (1 IN EP0)


XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};

int main(void)
{
  chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
  interface control i_control[1];
  par {
    on USB_TILE: par {
      endpoint0(c_ep_out[0], c_ep_in[0], i_control);
      XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                      null, epTypeTableOut, epTypeTableIn,
                      XUD_SPEED_HS, XUD_PWR_BUS);
    }
    on tile[0]: par {
      app(i_control[0]);
    }
  }
  return 0;
}
