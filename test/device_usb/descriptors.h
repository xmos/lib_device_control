#include "usb_std_requests.h"
#include "usb_std_descriptors.h"
#include "hid.h"

#define VENDOR_ID 0x20B1
#define PRODUCT_ID 0x1010

#define BCD_DEVICE 0x1000

#define EP0_MAX_PACKET_SIZE 64

unsigned char device_descriptor[] = {
  0x12,                  /* 0  bLength */
  USB_DESCTYPE_DEVICE,   /* 1  bdescriptorType */
  0x00,                  /* 2  bcdUSB */
  0x02,                  /* 3  bcdUSB */
  0x00,                  /* 4  bDeviceClass */
  0x00,                  /* 5  bDeviceSubClass */
  0x00,                  /* 6  bDeviceProtocol */
  EP0_MAX_PACKET_SIZE,   /* 7  bMaxPacketSize */
  (VENDOR_ID & 0xFF),    /* 8  idVendor */
  (VENDOR_ID >> 8),      /* 9  idVendor */
  (PRODUCT_ID & 0xFF),   /* 10 idProduct */
  (PRODUCT_ID >> 8),     /* 11 idProduct */
  (BCD_DEVICE & 0xFF),   /* 12 bcdDevice */
  (BCD_DEVICE >> 8),     /* 13 bcdDevice */
  0x01,                  /* 14 iManufacturer */
  0x02,                  /* 15 iProduct */
  0x00,                  /* 16 iSerialNumber */
  0x01                   /* 17 bNumConfigurations */
};

#define HID_INTERFACE_NUM 0

unsigned char configuration_descriptor[] = {
  0x09,                 /* 0  bLength */
  0x02,                 /* 1  bDescriptortype */
  0x22, 0x00,           /* 2  wTotalLength */
  0x01,                 /* 4  bNumInterfaces */
  0x01,                 /* 5  bConfigurationValue */
  0x03,                 /* 6  iConfiguration */
  0x80,                 /* 7  bmAttributes */
  0xC8,                 /* 8  bMaxPower */

  0x09,                 /* 0  bLength */
  0x04,                 /* 1  bDescriptorType */
  HID_INTERFACE_NUM,    /* 2  bInterfaceNumber */
  0x00,                 /* 3  bAlternateSetting */
  0x01,                 /* 4: bNumEndpoints */
  0x03,                 /* 5: bInterfaceClass */
  0x00,                 /* 6: bInterfaceSubClass */
  0x02,                 /* 7: bInterfaceProtocol*/
  0x00,                 /* 8  iInterface */

  0x09,                 /* 0  bLength. Note this is currently
                              replicated in hid_descriptor[] below */
  0x21,                 /* 1  bDescriptorType (HID) */
  0x10,                 /* 2  bcdHID */
  0x11,                 /* 3  bcdHID */
  0x00,                 /* 4  bCountryCode */
  0x01,                 /* 5  bNumDescriptors */
  0x22,                 /* 6  bDescriptorType[0] (Report) */
  0x48,                 /* 7  wDescriptorLength */
  0x00,                 /* 8  wDescriptorLength */

  0x07,                 /* 0  bLength */
  0x05,                 /* 1  bDescriptorType */
  0x81,                 /* 2  bEndpointAddress */
  0x03,                 /* 3  bmAttributes */
  0x40,                 /* 4  wMaxPacketSize */
  0x00,                 /* 5  wMaxPacketSize */
  0x01                  /* 6  bInterval */
};

unsigned char hid_descriptor[] = {
  0x09,               /* 0  bLength */
  0x21,               /* 1  bDescriptorType (HID) */
  0x10,               /* 2  bcdHID */
  0x11,               /* 3  bcdHID */
  0x00,               /* 4  bCountryCode */
  0x01,               /* 5  bNumDescriptors */
  0x22,               /* 6  bDescriptorType[0] (Report) */
  0x48,               /* 7  wDescriptorLength */
  0x00,               /* 8  wDescriptorLength */
};

unsafe{
  char *unsafe string_descriptors[] = {
    "\x09\x04",             // Language ID string (US English)
    "XMOS",                 // iManufacturer
    "XMOS USB example",     // iProduct
    "Config",               // iConfiguration
  };
}

unsigned char hid_report_descriptor[] = {
  0x05, 0x01,          // Usage page (desktop)
  0x09, 0x02,          // Usage (mouse)
  0xA1, 0x01,          // Collection (app)
  0x05, 0x09,          // Usage page (buttons)
  0x19, 0x01,
  0x29, 0x03,
  0x15, 0x00,          // Logical min (0)
  0x25, 0x01,          // Logical max (1)
  0x95, 0x03,          // Report count (3)
  0x75, 0x01,          // Report size (1)
  0x81, 0x02,          // Input (Data, Absolute)
  0x95, 0x01,          // Report count (1)
  0x75, 0x05,          // Report size (5)
  0x81, 0x03,          // Input (Absolute, Constant)
  0x05, 0x01,          // Usage page (desktop)
  0x09, 0x01,          // Usage (pointer)
  0xA1, 0x00,          // Collection (phys)
  0x09, 0x30,          // Usage (x)
  0x09, 0x31,          // Usage (y)
  0x15, 0x81,          // Logical min (-127)
  0x25, 0x7F,          // Logical max (127)
  0x75, 0x08,          // Report size (8)
  0x95, 0x02,          // Report count (2)
  0x81, 0x06,          // Input (Data, Rel=0x6, Abs=0x2)
  0xC0,                // End collection
  0x09, 0x38,          // Usage (Wheel)
  0x95, 0x01,          // Report count (1)
  0x81, 0x02,          // Input (Data, Relative)
  0x09, 0x3C,          // Usage (Motion Wakeup)
  0x15, 0x00,          // Logical min (0)
  0x25, 0x01,          // Logical max (1)
  0x75, 0x01,          // Report size (1)
  0x95, 0x01,          // Report count (1)
  0xB1, 0x22,          // Feature (No preferred, Variable)
  0x95, 0x07,          // Report count (7)
  0xB1, 0x01,          // Feature (Constant)
  0xC0                 // End collection
};
