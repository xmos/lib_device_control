// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#if CONTROL_USE_USB
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif
#include "libusb.h"

#include "control_host.h"
#include "control_host_support.h"
#include "control_host_util.h"

//#define DBG(x) x
#define DBG(x)
#define PRINT_ERROR(...)   fprintf(stderr, "Error  : " __VA_ARGS__)

static unsigned num_commands = 0;

static libusb_device_handle *devh = NULL;

static const int sync_timeout_ms = 500;

/* Control query transfers require smaller buffers */
#define VERSION_MAX_PAYLOAD_SIZE 64

void debug_libusb_error(int err_code)
{
  PRINT_ERROR("libusb_control_transfer returned %s\n", libusb_error_name(err_code));
}

control_ret_t control_special_command(const uint8_t cmd_id, const uint16_t payload_size, uint8_t* payload) {
  uint16_t windex, wvalue, wlength;
  uint8_t request_data[VERSION_MAX_PAYLOAD_SIZE];

  control_usb_fill_header(&windex, &wvalue, &wlength,
    CONTROL_SPECIAL_RESID, cmd_id, payload_size);

  DBG(printf("%u: send control command: 0x%04x 0x%04x 0x%04x\n",
    num_commands, windex, wvalue, wlength));

  int ret = libusb_control_transfer(devh,
    (uint8_t) LIBUSB_ENDPOINT_IN | (uint8_t) LIBUSB_REQUEST_TYPE_VENDOR | (uint8_t) LIBUSB_RECIPIENT_DEVICE,
    CONTROL_VENDOR_REQUEST, wvalue, windex, request_data, wlength, sync_timeout_ms);

  num_commands++;

  if (ret != sizeof(control_version_t)) {
    debug_libusb_error(ret);
    return CONTROL_ERROR;
  }

  memcpy(payload, request_data, payload_size);

  return CONTROL_SUCCESS;

}

control_ret_t control_query_version(control_version_t *version)
{
  control_ret_t ret = control_special_command(CONTROL_GET_VERSION, sizeof(control_version_t), version);

  DBG(printf("version returned: 0x%X\n", *version));

  return ret;
}

control_ret_t control_command_status(control_status_t *status)
{
  control_ret_t ret = control_special_command(CONTROL_GET_LAST_COMMAND_STATUS, sizeof(control_status_t), status);

  DBG(printf("status returned: 0x%X\n", *status));

  return ret;
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
    PRINT_ERROR("Control transfer of %zd bytes requested\n", payload_len);
    PRINT_ERROR("Maximum control packet size is %d\n", USB_TRANSACTION_MAX_BYTES);
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
  uint8_t status;

  if (payload_len_exceeds_control_packet_size(payload_len))
    return CONTROL_DATA_LENGTH_ERROR;

  control_usb_fill_header(&windex, &wvalue, &wlength,
    resid, CONTROL_CMD_SET_WRITE(cmd), (unsigned)payload_len);

  DBG(printf("%u: send write command: 0x%04x 0x%04x 0x%04x ",
    num_commands, windex, wvalue, wlength));
  DBG(print_bytes(payload, payload_len));

  int ret = libusb_control_transfer(devh,
    (uint8_t) LIBUSB_ENDPOINT_OUT | (uint8_t) LIBUSB_REQUEST_TYPE_VENDOR | (uint8_t) LIBUSB_RECIPIENT_DEVICE,
    CONTROL_VENDOR_REQUEST, wvalue, windex, (unsigned char*)payload, wlength, sync_timeout_ms);

  num_commands++;

  if (ret != (int)payload_len) {
    debug_libusb_error(ret);
    return CONTROL_ERROR;
  }

  // Read back write command status
  control_command_status(&status);

  return status;
}

control_ret_t
control_read_command(control_resid_t resid, control_cmd_t cmd,
                     uint8_t payload[], size_t payload_len)
{
  uint16_t windex, wvalue, wlength;

  if (payload_len_exceeds_control_packet_size(payload_len))
    return CONTROL_DATA_LENGTH_ERROR;

  control_usb_fill_header(&windex, &wvalue, &wlength,
    resid, CONTROL_CMD_SET_READ(cmd), (unsigned)payload_len);

  DBG(printf("%u: send read command: 0x%04x 0x%04x 0x%04x\n",
    num_commands, windex, wvalue, wlength));

  int ret = libusb_control_transfer(devh,
    (uint8_t) LIBUSB_ENDPOINT_IN | (uint8_t) LIBUSB_REQUEST_TYPE_VENDOR | (uint8_t) LIBUSB_RECIPIENT_DEVICE,
    CONTROL_VENDOR_REQUEST, wvalue, windex, payload, wlength, sync_timeout_ms);

  num_commands++;

  if (ret != (int)payload_len) {
    debug_libusb_error(ret);
    return CONTROL_ERROR;
  }

  DBG(printf("read data returned: "));
  DBG(print_bytes(payload, payload_len));

  return CONTROL_SUCCESS;
}

control_ret_t control_init_usb(int vendor_id, int product_id, int interface_num)
{
  (void)interface_num; // Deprecated parameter, no longer used

  int ret = libusb_init(NULL);
  if (ret < 0) {
    PRINT_ERROR("Failed to initialise libusb\n");
    return CONTROL_ERROR;
  }

  libusb_device **devs = NULL;
  ssize_t num_dev = libusb_get_device_list(NULL, &devs);

  libusb_device *dev = NULL;
  for (ssize_t i = 0; i < num_dev; i++) {
    struct libusb_device_descriptor desc;
    libusb_get_device_descriptor(devs[i], &desc);
    if (desc.idVendor == vendor_id && desc.idProduct == product_id) {
      dev = devs[i];
      break;
    }
  }

  if (dev == NULL) {
    PRINT_ERROR("Could not find device\n");
    return CONTROL_ERROR;
  }

  if (libusb_open(dev, &devh) < 0) {
    PRINT_ERROR("Failed to open device. Ensure adequate permissions\n");
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

#endif // CONTROL_USE_USB
