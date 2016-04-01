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

enum {
  COMMAND_GET = 1,
  COMMAND_SET = 2
};

struct command {
  uint8_t direction;
  uint8_t entity;
  uint8_t address[3]; /* big endian convention */
  uint8_t payload_length;
  uint8_t payload[64]; /* USB control request maximum, xSCOPE is probably 256 */
};

unsigned ntoh24(const unsigned char b[3])
{
  return ((unsigned)b[0] << 16) | ((unsigned)b[1] << 8) | (unsigned)b[0];
}

[[combinable]]
void usb_server(chanend c_vendor_request, chanend c_app)
{
  unsigned direction, index, value, length;
  struct command c;
  int i;

  while (1) {
    select {
      case c_vendor_request :> direction:
	/* USB to app translation is done here */
	switch (direction) {
	  case 0: c.direction = COMMAND_SET; break;
	  case 1: c.direction = COMMAND_GET; break;
	}
	slave {
	  c_vendor_request :> index;
	  c_vendor_request :> value;
	  c_vendor_request :> length;
	  if (c.direction == COMMAND_SET) {
	    for (i = 0; i < length; i++) {
	      c_vendor_request :> c.payload[i];
	    }
	  }
	  c.entity = index & 0xFF;
	  c.address[0] = (index >> 8);
	  c.address[1] = value & 0xFF;
	  c.address[2] = (value >> 8);
	  c.payload_length = length;
	}
	c_app <: c.direction;
	master {
          c_app <: ntoh24(c.address);
          c_app <: c.payload_length;
	  if (c.direction == COMMAND_SET) {
	    for (i = 0; i < c.payload_length; i++) {
	      c_app <: c.payload[i];
	    }
	  }
	}
	if (c.direction == COMMAND_GET) {
          slave {
            for (i = 0; i < c.payload_length; i++) {
              c_app :> c.payload[i];
            }
	  }
	  master {
	    for (i = 0; i < c.payload_length; i++) {
	      c_vendor_request <: c.payload[i];
	    }
	  }
	}
	/* XUD task defers further calls by NAKing USB transactions */
	break;
    }
  }
}

void app(chanend c_app)
{
  char direction;
  int address;
  char n;
  int i;
  unsigned char payload[8];
  unsigned num_commands;

  printf("started\n");

  num_commands = 0;

  while (1) {
    select {
      case c_app :> direction:
        slave {
          c_app :> address;
          c_app :> n;
          if (direction == COMMAND_SET) {
            assert(n <= sizeof(payload));
            for (i = 0; i < n; i++) {
              c_app :> payload[i];
            }
          }
        }
        if (direction == COMMAND_GET) {
          master {
            assert(n == 4);
            c_app <: (char)0x12;
            c_app <: (char)0x34;
            c_app <: (char)0x56;
            c_app <: (char)0x78;
          }
        }
        printf("%u: received %s: 0x%06x %d,", num_commands, direction == COMMAND_GET ? "GET" : "SET", address, n);
        if (direction == COMMAND_SET) {
          for (i = 0; i < n; i++) {
            printf(" %02x", payload[i]);
          }
        }
        else {
          printf(" returned %d bytes", n);
        }
        printf("\n");
        num_commands++;
        break;
    }
  }
}

void endpoint0(chanend c_ep0_out, chanend c_ep0_in, chanend c_vendor_request)
{
  USB_SetupPacket_t sp;
  XUD_Result_t res;
  XUD_BusSpeed_t bus_speed;
  XUD_ep ep0_out, ep0_in;
  unsigned short descriptor_type;
  unsigned char zero_hid_report[] = {0, 0, 0, 0};
  unsigned char request_data[EP0_MAX_PACKET_SIZE];
  unsigned request_data_length;
  int i;

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
	    c_vendor_request <: (int)sp.bmRequestType.Direction;
	    master {
	      c_vendor_request <: (int)sp.wIndex;
	      c_vendor_request <: (int)sp.wValue;
	      c_vendor_request <: (int)sp.wLength;
	      for (i = 0; i < request_data_length; i++) {
		c_vendor_request <: request_data[i];
	      }
	    }
	    res = XUD_DoSetRequestStatus(ep0_in);
	  }
	  break;

	case USB_BMREQ_D2H_VENDOR_DEV:
	  request_data_length = sp.wLength;
	  c_vendor_request <: (int)sp.bmRequestType.Direction;
	  master {
	    c_vendor_request <: (int)sp.wIndex;
	    c_vendor_request <: (int)sp.wValue;
	    c_vendor_request <: (int)sp.wLength;
	  }
	  /* application retrieval latency here */
	  slave {
	    for (i = 0; i < request_data_length; i++) {
	      c_vendor_request :> request_data[i];
	    }
	  }
	  res = XUD_DoGetRequest(ep0_out, ep0_in, request_data, request_data_length, request_data_length);
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
  chan c_vendor_request;
  chan c_app;
  par {
    on USB_TILE: par {
      app(c_app);
      usb_server(c_vendor_request, c_app);
      hid_endpoint(c_ep_in[1]);
      endpoint0(c_ep_out[0], c_ep_in[0], c_vendor_request);

      { ep_out[EP_OUT_ZERO] = XUD_EPTYPE_CTL | XUD_STATUS_ENABLE;
        ep_in[EP_OUT_ZERO] = XUD_EPTYPE_CTL | XUD_STATUS_ENABLE;
	ep_in[EP_IN_HID] = XUD_EPTYPE_BUL;
        XUD_Manager(c_ep_out, NUM_EP_OUT, c_ep_in, NUM_EP_IN, null, ep_out, ep_in, null, null, -1, XUD_SPEED_HS, XUD_PWR_SELF);
      }
    }
  }
  return 0;
}
