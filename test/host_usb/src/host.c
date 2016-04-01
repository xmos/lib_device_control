#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "util.h"
#include "signals.h"
#include "command.h"
#include "libusb.h"

#define VENDOR_ID 0x20B1
#define PRODUCT_ID 0x1010

unsigned num_commands = 0;

libusb_device **devs = NULL;
libusb_device_handle *devh = NULL;

static const int sync_timeout_ms = 100;

void do_set_command(void)
{
  struct command c;
  unsigned char *cb;
  unsigned char payload[1];
  uint16_t value, index;
  int ret, len;

  /* make a SET command for mic gain
   * use entity number to refer to Illusonic library as "client 0"
   * use property number to select INIT module, 0x4100
   * and mic gain parameter, 0x49 (ASCII 'I') --> 0x494100
   * send 8bit value of 1 as data
   */
  cb = (void*)&c;
  payload[0] = 1;
  len = make_command(&c, COMMAND_SET, 0, 0x494100, 1, payload);

  printf("%u: send SET command: ", num_commands);
  print_bytes(cb, len);

  /* encode 1+3 bytes of entity/address in 2+2 bytes of index/value */
  index = c.entity | ((unsigned)c.address[0] << 8);
  value = c.address[1] | ((unsigned)c.address[2] << 8);

  ret = libusb_control_transfer(devh,
    LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, value, index, c.payload, c.payload_length, sync_timeout_ms);

  if (ret != c.payload_length)
    printf("libusb_control_transfer returned %d\n", ret);

  num_commands++;
}

void do_get_command(void)
{
  struct command c;
  unsigned char *cb;
  uint16_t value, index;
  int ret, len;

  /* make a GET command for diagnostics
   * use entity number to refer to Illusonic library as "client 0"
   * use address to select DIAG module, 0x4C00
   * and diagnostics parameter, 0x45 (ASCII 'E') --> 0x454C00
   * request 4 bytes back
   */
  cb = (void*)&c;
  len = make_command(&c, COMMAND_GET, 0, 0x454C00, 4, NULL);

  printf("%d: send GET command: ", num_commands);
  print_bytes(cb, len);

  /* encode 1+3 bytes of entity/address in 2+2 bytes of index/value */
  index = c.entity | ((unsigned)c.address[0] << 8);
  value = c.address[1] | ((unsigned)c.address[2] << 8);

  ret = libusb_control_transfer(devh,
    LIBUSB_ENDPOINT_IN | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, value, index, c.payload, c.payload_length, sync_timeout_ms);

  if (ret != c.payload_length)
    printf("libusb_control_transfer returned %d\n", ret);

  printf("GET data returned: ");
  print_bytes(c.payload, c.payload_length);

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
      do_set_command();

      if (!done)
        usleep(100000);

      do_get_command();

      if (!done)
        sleep(1);
    }
  }

  cleanup_usb();
  return 0;
}
