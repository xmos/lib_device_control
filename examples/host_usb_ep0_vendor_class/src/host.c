// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#include <windows.h>
#include "usb.h"
#else
#include <unistd.h>
#include "libusb.h"
#endif

#include "util.h"
#include "signals.h"
#include "control_host.h"
#include "resource.h"

static unsigned num_commands = 0;

#ifdef _WIN32
static usb_dev_handle *devh = NULL;
#else
static libusb_device_handle *devh = NULL;
#endif

static const int sync_timeout_ms = 100;

void do_write_command(void)
{
  uint16_t windex, wvalue, wlength;
  unsigned char payload[1];

  payload[0] = 1;
  control_usb_ep0_fill_header(&windex, &wvalue, &wlength,
    RESOURCE_ID_HASH, CONTROL_CMD_SET_WRITE(0), sizeof(payload));

  printf("%u: send write command: 0x%04x 0x%04x 0x%04x ",
    num_commands, windex, wvalue, wlength);
  print_bytes(payload, sizeof(payload));

#ifdef _WIN32
  int ret = usb_control_msg(devh,
    USB_ENDPOINT_OUT | USB_TYPE_VENDOR | USB_RECIP_DEVICE,
    0, wvalue, windex, (char*)payload, wlength, sync_timeout_ms);
#else
  int ret = libusb_control_transfer(devh,
    LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, wvalue, windex, payload, wlength, sync_timeout_ms);
#endif

  if (ret != sizeof(payload)) {
    printf("libusb_control_transfer returned %d\n", ret);
  }

  num_commands++;
}

void do_read_command(void)
{
  uint16_t windex, wvalue, wlength;
  unsigned char payload[4];

  control_usb_ep0_fill_header(&windex, &wvalue, &wlength,
    RESOURCE_ID_HASH, CONTROL_CMD_SET_READ(0), sizeof(payload));

  printf("%u: send read command: 0x%04x 0x%04x 0x%04x\n",
    num_commands, windex, wvalue, wlength);

#ifdef _WIN32
  int ret = usb_control_msg(devh,
    USB_ENDPOINT_IN | USB_TYPE_VENDOR | USB_RECIP_DEVICE,
    0, wvalue, windex, (char*)payload, wlength, sync_timeout_ms);
#else
  int ret = libusb_control_transfer(devh,
    LIBUSB_ENDPOINT_IN | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, wvalue, windex, payload, wlength, sync_timeout_ms);
#endif

  if (ret != sizeof(payload)) {
    printf("libusb_control_transfer returned %d\n", ret);
  }

  printf("read data returned: ");
  print_bytes(payload, sizeof(payload));

  num_commands++;
}

#ifdef _WIN32

static void find_xmos_device(int vendor_id, int product_id)
{
  for (struct usb_bus *bus = usb_get_busses(); bus && !devh; bus = bus->next) {
    for (struct usb_device *dev = bus->devices; dev; dev = dev->next) {
      if ((dev->descriptor.idVendor == vendor_id) &&
              (dev->descriptor.idProduct == product_id)) {
        devh = usb_open(dev);
        if (!devh) {
          fprintf(stderr, "failed to open device\n");
          exit(1);
        }
        break;
      }
    }
  }

  if (!devh) {
    fprintf(stderr, "could not find device\n");
    exit(1);
  }
}

static int init_usb(int vendor_id, int product_id)
{
  usb_init();
  usb_find_busses(); /* find all busses */
  usb_find_devices(); /* find all connected devices */

  find_xmos_device(vendor_id, product_id);

  int r = usb_set_configuration(devh, 1);
  if (r < 0) {
    fprintf(stderr, "Error setting config 1\n");
    usb_close(devh);
    return -1;
  }

  r = usb_claim_interface(devh, 0);
  if (r < 0) {
    fprintf(stderr, "Error claiming interface %d %d\n", 0, r);
    return -1;
  }

  return 0;
}

static void cleanup_usb() {
  usb_release_interface(devh, 0);
  usb_close(devh);
}

static void pause_short(int done)
{
  if (!done) {
    Sleep(1);
  }
}

static void pause_long(int done)
{
  if (!done) {
    Sleep(1000);
  }
}

#else

static void init_usb(int vendor_id, int product_id)
{
  int ret = libusb_init(NULL);
  if (ret < 0) {
    fprintf(stderr, "failed to initialise libusb\n");
    exit(1);
  }

  libusb_device **devs = NULL;
  libusb_get_device_list(NULL, &devs);

  libusb_device *dev = NULL;
  for (int i = 0; devs[i] != NULL; i++) {
    struct libusb_device_descriptor desc;
    libusb_get_device_descriptor(devs[i], &desc);
    if (desc.idVendor == vendor_id && desc.idProduct == product_id) {
      dev = devs[i];
      break;
    }
  }

  if (dev == NULL) {
    fprintf(stderr, "could not find device\n");
    exit(1);
  }

  if (libusb_open(dev, &devh) < 0) {
    fprintf(stderr, "failed to open device\n");
    exit(1);
  }

  libusb_free_device_list(devs, 1);
}

static void cleanup_usb(void)
{
  libusb_close(devh);
  libusb_exit(NULL);
}

static void pause_short(int done)
{
  if (!done) {
    usleep(100000);
  }
}

static void pause_long(int done)
{
  if (!done) {
    sleep(1);
  }
}

#endif // _WIN32

int done = 0;

void shutdown(void)
{
  done = 1;
}

int main(void)
{
  int vendor_id = 0x20B1;
  int product_id = 0x1010;

  int i;

  signals_init();
  init_usb(vendor_id, product_id);
  signals_setup_int(shutdown);

  while (!done) {
    for (i = 0; !done && i < 4; i++) {
      do_write_command();

      pause_short(done);
      do_read_command();
      pause_long(done);
    }
  }

  cleanup_usb();
  return 0;
}
