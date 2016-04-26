#include <platform.h>
#include <assert.h>
#include <xscope.h>
#include <stdio.h>
#include <stdint.h>
#include "debug_print.h"
#include "xud.h"
#include "usb_std_requests.h"
#include "usb_device.h"
#include "hid.h"
#include "descriptors.h"
#include "control.h"

void app(server interface control i_module)
{
  unsigned num_commands;
  int i;

  printf("started\n");

  num_commands = 0;

  while (1) {
    select {
      case i_module.set(int address, size_t payload_size, const uint8_t payload[]):
        printf("%u: received SET: 0x%06x %d,", num_commands, address, payload_size);
        for (i = 0; i < payload_size; i++) {
          printf(" %02x", payload[i]);
        }
        printf("\n");
        num_commands++;
        break;

      case i_module.get(int address, size_t payload_size, uint8_t payload[]):
        assert(payload_size == 4);
        payload[0] = 0x12;
        payload[1] = 0x34;
        payload[2] = 0x56;
        payload[3] = 0x78;
        printf("%u: received GET: 0x%06x %d,", num_commands, address, payload_size);
        printf(" returned %d bytes", payload_size);
        printf("\n");
        num_commands++;
        break;
    }
  }
}

void endpoint0(chanend c_ep0_out, chanend c_ep0_in, client interface control i_module[1])
{
  USB_SetupPacket_t sp;
  XUD_Result_t res;
  XUD_BusSpeed_t bus_speed;
  XUD_ep ep0_out, ep0_in;
  unsigned short descriptor_type;
  unsigned char zero_hid_report[] = {0, 0, 0, 0};
  unsigned char request_data[EP0_MAX_PACKET_SIZE];
  unsigned request_data_length;
  size_t return_size;

  ep0_out = XUD_InitEp(c_ep0_out);
  ep0_in = XUD_InitEp(c_ep0_in);

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
	  request_data_length = 0; /* length not required by XUD API coming in */
	  res = XUD_GetBuffer(ep0_out, request_data, request_data_length);
	  if (res == XUD_RES_OKAY) {
            control_handle_message_usb(sp.bmRequestType.Direction, sp.wIndex, sp.wValue, sp.wLength,
              request_data, request_data_length, return_size, i_module, 1);
	    res = XUD_DoSetRequestStatus(ep0_in);
	  }
	  break;

	case USB_BMREQ_D2H_VENDOR_DEV:
	  /* application retrieval latency inside the control library call
           * XUD task defers further calls by NAKing USB transactions
           */
          control_handle_message_usb(sp.bmRequestType.Direction, sp.wIndex, sp.wValue, sp.wLength,
            request_data, request_data_length, return_size, i_module, 1);
	  res = XUD_DoGetRequest(ep0_out, ep0_in, request_data, return_size, return_size);
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
  XUD_ep ep = XUD_InitEp(c_ep_hid);
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

XUD_EpType ep_out[NUM_EP_OUT];
XUD_EpType ep_in[NUM_EP_IN];

int main(void)
{
  chan c_ep_out[NUM_EP_OUT], c_ep_in[NUM_EP_IN];
  interface control i_module[1];
  par {
    on USB_TILE: par {
      app(i_module[0]);
      hid_endpoint(c_ep_in[1]);
      endpoint0(c_ep_out[0], c_ep_in[0], i_module);

      { ep_out[EP_OUT_ZERO] = XUD_EPTYPE_CTL | XUD_STATUS_ENABLE;
        ep_in[EP_OUT_ZERO] = XUD_EPTYPE_CTL | XUD_STATUS_ENABLE;
	ep_in[EP_IN_HID] = XUD_EPTYPE_BUL;
        XUD_Manager(c_ep_out, NUM_EP_OUT, c_ep_in, NUM_EP_IN, null, ep_out, ep_in, null, null, -1, XUD_SPEED_HS, XUD_PWR_SELF);
      }
    }
  }
  return 0;
}
