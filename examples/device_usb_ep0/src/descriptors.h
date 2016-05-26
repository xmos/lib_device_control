#include "usb.h"

#define EP0_MAX_PACKET_SIZE 64

#define BCD_DEVICE              0x1000
#define VENDOR_ID               0x20B1
#define PRODUCT_ID              0x1010
#define MANUFACTURER_STR_INDEX  0x0001
#define PRODUCT_STR_INDEX       0x0002

/* Vendor specific class defines */
#define VENDOR_SPECIFIC_CLASS    0xff
#define VENDOR_SPECIFIC_SUBCLASS 0xff
#define VENDOR_SPECIFIC_PROTOCOL 0xff

/* Device Descriptor */
static unsigned char devDesc[] =
{
    0x12,                     /* 0  bLength */
    USB_DESCTYPE_DEVICE,      /* 1  bdescriptorType */
    0x00,                     /* 2  bcdUSB */
    0x02,                     /* 3  bcdUSB */
    VENDOR_SPECIFIC_CLASS,    /* 4  bDeviceClass */
    VENDOR_SPECIFIC_SUBCLASS, /* 5  bDeviceSubClass */
    VENDOR_SPECIFIC_PROTOCOL, /* 6  bDeviceProtocol */
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
    0x09,                     /* 0  bLength */
    0x02,                     /* 1  bDescriptortype */
    0x20, 0x00,               /* 2  wTotalLength */
    0x01,                     /* 4  bNumInterfaces */
    0x01,                     /* 5  bConfigurationValue */
    0x00,                     /* 6  iConfiguration */
    0x80,                     /* 7  bmAttributes */
    0xFA,                     /* 8  bMaxPower */

    0x09,                     /* 0  bLength */
    0x04,                     /* 1  bDescriptorType */
    0x00,                     /* 2  bInterfacecNumber */
    0x00,                     /* 3  bAlternateSetting */
    0x02,                     /* 4: bNumEndpoints */
    0xFF,                     /* 5: bInterfaceClass */
    0xFF,                     /* 6: bInterfaceSubClass */
    0xFF,                     /* 7: bInterfaceProtocol*/
    0x03,                     /* 8  iInterface */

    0x07,                     /* 0  bLength */
    0x05,                     /* 1  bDescriptorType */
    0x01,                     /* 2  bEndpointAddress */
    0x02,                     /* 3  bmAttributes */
    0x00,                     /* 4  wMaxPacketSize */
    0x02,                     /* 5  wMaxPacketSize */
    0x01,                     /* 6  bInterval */

    0x07,                     /* 0  bLength */
    0x05,                     /* 1  bDescriptorType */
    0x81,                     /* 2  bEndpointAddress */
    0x02,                     /* 3  bmAttributes */
    0x00,                     /* 4  wMaxPacketSize */
    0x02,                     /* 5  wMaxPacketSize */
    0x01                      /* 6  bInterval */
};

unsafe
{
  static char * unsafe stringDescriptors[] =
  {
      "\x09\x04",                             // Language ID string (US English)
      "XMOS",                                 // iManufacturer
      "XMOS Custom Device Test",              // iProduct
      "Custom Interface",                     // iInterface
      "Config",                               // iConfiguration
  };
}