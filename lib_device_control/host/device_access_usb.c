// Copyright (c) 2016-2018, XMOS Ltd, All rights reserved
#if USE_USB
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#ifdef _WIN32
#include <windows.h>
#include "usb.h"
#else
#include <unistd.h>
#include "libusb.h"
#endif
#include "control_host.h"
#include "control_host_support.h"
#include "util.h"

//#define DBG(x) x
#define DBG(x)

static unsigned num_commands = 0;

#ifdef _WIN32
static usb_dev_handle *devh = NULL;
#else
static libusb_device_handle *devh = NULL;
#endif

static const int sync_timeout_ms = 100;

/* Control query transfers require smaller buffers */
#define VERSION_MAX_PAYLOAD_SIZE 64

void debug_libusb_error(int err_code)
{
#if defined _WIN32
  /* err_code is not used in Windows platforms */
  (void) err_code;
  printf("libusb_control_transfer returned %s\n", usb_strerror());
#elif defined __APPLE__
  printf("libusb_control_transfer returned %s\n", libusb_error_name(err_code));
#elif defined __linux
  printf("libusb_control_transfer returned %d\n", err_code);
#endif

}

control_ret_t control_query_version(control_version_t *version)
{
  uint16_t windex, wvalue, wlength;
  uint8_t request_data[VERSION_MAX_PAYLOAD_SIZE];

  control_usb_fill_header(&windex, &wvalue, &wlength,
    CONTROL_SPECIAL_RESID, CONTROL_GET_VERSION, sizeof(control_version_t));

  DBG(printf("%u: send version command: 0x%04x 0x%04x 0x%04x\n",
    num_commands, windex, wvalue, wlength));

#ifdef _WIN32
  int ret = usb_control_msg(devh,
    USB_ENDPOINT_IN | USB_TYPE_VENDOR | USB_RECIP_DEVICE,
    0, wvalue, windex, (char*)request_data, wlength, sync_timeout_ms);
#else
  int ret = libusb_control_transfer(devh,
    LIBUSB_ENDPOINT_IN | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, wvalue, windex, request_data, wlength, sync_timeout_ms);
#endif

  num_commands++;

  if (ret != sizeof(control_version_t)) {
    debug_libusb_error(ret);
    return CONTROL_ERROR;
  }

  memcpy(version, request_data, sizeof(control_version_t));
  DBG(printf("version returned: 0x%X\n", *version));

  return CONTROL_SUCCESS;
}

/*
 * Ideally we would examine configuration descriptors and check for actual
 * wMaxPacketSize on given control endpoint.
 *
 * For now, just assume the greatest control transfer size, USB_TRANSACTION_MAX_BYTES. Have host
 * code only check payload size here. Device will not need any additional
 * checks. Device application code will set wMaxPacketSize in its
 * descriptors and take care of allocating a buffer for receiving control
 * requests of up to USB_TRANSACTION_MAX_BYTES bytes.
 *
 * Without checking, libusb would set wLength in header to any number and
 * only send 64 bytes of payload, truncating the rest.
 */
static bool payload_len_exceeds_control_packet_size(size_t payload_len)
{
  if (payload_len > USB_TRANSACTION_MAX_BYTES) {
    printf("control transfer of %zd bytes requested\n", payload_len);
    printf("maximum control packet size is %d\n", USB_TRANSACTION_MAX_BYTES);
    return true;
  }
  else {
    return false;
  }
}

control_ret_t
control_write_command(control_resid_t resid, control_cmd_t cmd,
                      const uint8_t payload[], size_t payload_len)
{
  uint16_t windex, wvalue, wlength;

  if (payload_len_exceeds_control_packet_size(payload_len))
    return CONTROL_DATA_LENGTH_ERROR;

  control_usb_fill_header(&windex, &wvalue, &wlength,
    resid, CONTROL_CMD_SET_WRITE(cmd), payload_len);

  DBG(printf("%u: send write command: 0x%04x 0x%04x 0x%04x ",
    num_commands, windex, wvalue, wlength));
  DBG(print_bytes(payload, payload_len));

#ifdef _WIN32
  int ret = usb_control_msg(devh,
    USB_ENDPOINT_OUT | USB_TYPE_VENDOR | USB_RECIP_DEVICE,
    0, wvalue, windex, (char*)payload, wlength, sync_timeout_ms);
#else
  int ret = libusb_control_transfer(devh,
    LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, wvalue, windex, (unsigned char*)payload, wlength, sync_timeout_ms);
#endif

  num_commands++;

  if (ret != (int)payload_len) {
    debug_libusb_error(ret);
    return CONTROL_ERROR;
  }

  return CONTROL_SUCCESS;
}

control_ret_t
control_read_command(control_resid_t resid, control_cmd_t cmd,
                     uint8_t payload[], size_t payload_len)
{
  uint16_t windex, wvalue, wlength;

  if (payload_len_exceeds_control_packet_size(payload_len))
    return CONTROL_DATA_LENGTH_ERROR;

  control_usb_fill_header(&windex, &wvalue, &wlength,
    resid, CONTROL_CMD_SET_READ(cmd), payload_len);

  DBG(printf("%u: send read command: 0x%04x 0x%04x 0x%04x\n",
    num_commands, windex, wvalue, wlength));

#ifdef _WIN32
  int ret = usb_control_msg(devh,
    USB_ENDPOINT_IN | USB_TYPE_VENDOR | USB_RECIP_DEVICE,
    0, wvalue, windex, (char*)payload, wlength, sync_timeout_ms);
#else
  int ret = libusb_control_transfer(devh,
    LIBUSB_ENDPOINT_IN | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, wvalue, windex, payload, wlength, sync_timeout_ms);
#endif

  num_commands++;

  if (ret != (int)payload_len) {
    debug_libusb_error(ret);
    return CONTROL_ERROR;
  }

  DBG(printf("read data returned: "));
  DBG(print_bytes(payload, payload_len));

  return CONTROL_SUCCESS;
}

#ifdef _WIN32

static control_ret_t find_xmos_device(int vendor_id, int product_id)
{
  for (struct usb_bus *bus = usb_get_busses(); bus && !devh; bus = bus->next) {
    for (struct usb_device *dev = bus->devices; dev; dev = dev->next) {
      if ((dev->descriptor.idVendor == vendor_id) &&
              (dev->descriptor.idProduct == product_id)) {
        devh = usb_open(dev);
        if (!devh) {
          fprintf(stderr, "failed to open device\n");
          return CONTROL_ERROR;
        }
        break;
      }
    }
  }

  if (!devh) {
    fprintf(stderr, "could not find device\n");
    return CONTROL_ERROR;
  }

  return CONTROL_SUCCESS;
}

control_ret_t control_init_usb(int vendor_id, int product_id, int interface_num)
{
  usb_init();
  usb_find_busses(); /* find all busses */
  usb_find_devices(); /* find all connected devices */

  if (find_xmos_device(vendor_id, product_id) != CONTROL_SUCCESS)
      return CONTROL_ERROR;

  int r = usb_set_configuration(devh, 1);
  if (r < 0) {
    fprintf(stderr, "Error setting config 1\n");
    usb_close(devh);
    return CONTROL_ERROR;
  }

  r = usb_claim_interface(devh, interface_num);
  if (r < 0) {
    fprintf(stderr, "Error claiming interface %d %d\n", interface_num, r);
    return CONTROL_ERROR;
  }

  return CONTROL_SUCCESS;
}

control_ret_t control_cleanup_usb(void)
{
  usb_release_interface(devh, 0);
  usb_close(devh);
  return CONTROL_SUCCESS;
}

control_ret_t list_connected_devices(int vendor_id)
{
  uint8_t num_devices = 0;
  uint32_t current_pid = 0;
  usb_init();
  usb_find_busses(); /* find all busses */
  usb_find_devices(); /* find all connected devices */
  /* Scan for connected devices with the given vendor_id*/
  for (struct usb_bus *bus = usb_get_busses(); bus && !devh; bus = bus->next) {
    for (struct usb_device *dev = bus->devices; dev; dev = dev->next) {
      if (dev->descriptor.idVendor == vendor_id) {
        devh = usb_open(dev);
        if (!devh) {
          fprintf(stderr, "Failed to open device with Product ID: %#06x\n", dev->descriptor.idProduct);
          return CONTROL_ERROR;
        }
        /* If the PID is new, update current_pid and print it */
        if (dev->descriptor.idProduct != current_pid) {
          current_pid = dev->descriptor.idProduct;
          printf("Found device with Product ID: %#06x\n", current_pid);
          /* Increment num_devices */
          num_devices++;
        }
      }
    }
  }
  /* Print the number of connected devices */
  if (!num_devices) {
    fprintf(stderr, "No device is connected\n");
    return CONTROL_ERROR;
  } else {
    printf("Found %d device(s)\n", num_devices);
  }
  return CONTROL_SUCCESS;
}

#else

control_ret_t control_init_usb(int vendor_id, int product_id, int interface_num)
{
  int ret = libusb_init(NULL);
  if (ret < 0) {
    fprintf(stderr, "failed to initialise libusb\n");
    return CONTROL_ERROR;
  }

  libusb_device **devs = NULL;
  int num_dev = libusb_get_device_list(NULL, &devs);

  libusb_device *dev = NULL;
  for (int i = 0; i < num_dev; i++) {
    struct libusb_device_descriptor desc;
    libusb_get_device_descriptor(devs[i], &desc);
    if (desc.idVendor == vendor_id && desc.idProduct == product_id) {
      dev = devs[i];
      break;
    }
  }

  if (dev == NULL) {
    fprintf(stderr, "could not find device\n");
    return CONTROL_ERROR;
  }

  if (libusb_open(dev, &devh) < 0) {
    fprintf(stderr, "failed to open device. Ensure adequate permissions\n");
    return CONTROL_ERROR;
  }

  libusb_free_device_list(devs, 1);

  return CONTROL_SUCCESS;
}

control_ret_t control_cleanup_usb(void)
{
  libusb_close(devh);
  libusb_exit(NULL);

  return CONTROL_SUCCESS;
}


control_ret_t list_connected_devices(int vendor_id)
{
  uint8_t num_devices = 0;
  uint32_t current_pid = 0;

  int ret = libusb_init(NULL);
  if (ret < 0) {
    fprintf(stderr, "failed to initialise libusb\n");
    return CONTROL_ERROR;
  }

  libusb_device **devs = NULL;
  int num_dev = libusb_get_device_list(NULL, &devs);
  struct libusb_device_descriptor desc;
  /* Scan for connected devices with the given vendor_id*/
  for (int dev_idx=0; dev_idx<num_dev; dev_idx++) { 
    libusb_get_device_descriptor(devs[dev_idx], &desc);
    if (desc.idVendor == vendor_id) {
      current_pid = desc.idProduct;
      printf("Found device with Product ID: %#06x\n", current_pid);
      /* Increment num_devices */
      num_devices++;
    }
  }
  /* Print the number of connected devices */
  if (!num_devices) {
    fprintf(stderr, "No device is connected\n");
    return CONTROL_ERROR;
  } else {
    printf("Found %d device(s)\n", num_devices);
  }
  return CONTROL_SUCCESS;
}

#endif // _WIN32

#endif // USE_USB
