// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "util.h"
#include "signals.h"
#include "libusb.h"
#include "control_host.h"
#include "resource.h"

#define VENDOR_ID 0x20B1
#define PRODUCT_ID 0x1010

unsigned num_commands = 0;

libusb_device **devs = NULL;
libusb_device_handle *devh = NULL;

static const int sync_timeout_ms = 100;

void do_write_command(void)
{
  uint16_t windex, wvalue, wlength;
  unsigned char payload[1];
  int ret;

  payload[0] = 1;
  control_usb_ep0_fill_header(&windex, &wvalue, &wlength,
    RESOURCE_ID_HASH, CONTROL_CMD_SET_WRITE(0), sizeof(payload));

  printf("%u: send write command: 0x%04x 0x%04x 0x%04x ",
    num_commands, windex, wvalue, wlength);
  print_bytes(payload, sizeof(payload));

  ret = libusb_control_transfer(devh,
    LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, wvalue, windex, payload, wlength, sync_timeout_ms);

  if (ret != sizeof(payload))
    printf("libusb_control_transfer returned %d\n", ret);

  num_commands++;
}

void do_read_command(void)
{
  uint16_t windex, wvalue, wlength;
  unsigned char payload[4];
  int ret;

  control_usb_ep0_fill_header(&windex, &wvalue, &wlength,
    RESOURCE_ID_HASH, CONTROL_CMD_SET_READ(0), sizeof(payload));

  printf("%u: send read command: 0x%04x 0x%04x 0x%04x\n",
    num_commands, windex, wvalue, wlength);

  ret = libusb_control_transfer(devh,
    LIBUSB_ENDPOINT_IN | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, wvalue, windex, payload, wlength, sync_timeout_ms);

  if (ret != sizeof(payload))
    printf("libusb_control_transfer returned %d\n", ret);

  printf("read data returned: ");
  print_bytes(payload, sizeof(payload));

  num_commands++;
}

void init_usb(int vendor_id, int product_id)
{
  int ret;
  libusb_device *dev;
  struct libusb_device_descriptor desc;
  int i;

  ret = libusb_init(NULL);
  if (ret < 0) {
    fprintf(stderr, "failed to initialise libusb\n");
    exit(1);
  }
  
  libusb_get_device_list(NULL, &devs);

  dev = NULL;
  for (i = 0; devs[i] != NULL; i++) {
    libusb_get_device_descriptor(devs[i], &desc); 
    if (desc.idVendor == VENDOR_ID && desc.idProduct == PRODUCT_ID) {
      dev = devs[i];
      break;
    }
  }

  if (dev == NULL) {
    fprintf(stderr, "could not find device\n");
    exit(1);
  }

  if (libusb_open(dev, &devh) < 0) {
    fprintf(stderr, "could not find device\n");
    exit(1);
  }
}

void cleanup_usb(void)
{
  libusb_free_device_list(devs, 1);
  libusb_close(devh);
  libusb_exit(NULL);
}

int done = 0;

void shutdown(void)
{
  done = 1;
}

int main(void)
{
  int i;

  signals_init();
  init_usb(VENDOR_ID, PRODUCT_ID);
  signals_setup_int(shutdown);

  while (!done) {
    for (i = 0; !done && i < 4; i++) {
      do_write_command();

      if (!done)
        usleep(100000);

      do_read_command();

      if (!done)
        sleep(1);
    }
  }

  cleanup_usb();
  return 0;
}
