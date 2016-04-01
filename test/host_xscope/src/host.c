#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>
#include <stdint.h>
#include "xscope_endpoint.h"
#include "command.h"
#include "util.h"
#include "signals.h"

#define PROBE_NAME "Upstream Data"

int probe_id = -1;
int record_count = 0;

void register_callback(unsigned int id, unsigned int type,
  unsigned int r, unsigned int g, unsigned int b,
  unsigned char *name, unsigned char *unit,
  unsigned int data_type, unsigned char *data_name)
{
  if (strcmp((char*)name, PROBE_NAME) == 0) {
    probe_id = id;
    printf("registered probe %d\n", id);
  }
}

void record_callback(unsigned int id, unsigned long long timestamp,
  unsigned int length, unsigned long long dataval, unsigned char *databytes)
{
  if (id == probe_id) {
    printf("GET data returned: ");
    print_bytes(databytes, length);
    record_count++;
  }
}

void init_xscope(int port)
{
  char port_str[16];

  sprintf(port_str, "%d", port);

  if (xscope_ep_set_register_cb(register_callback) != XSCOPE_EP_SUCCESS) {
    fprintf(stderr, "xscope_ep_set_register_cb failed\n");
    exit(1);
  }

  if (xscope_ep_set_record_cb(record_callback) != XSCOPE_EP_SUCCESS) {
    fprintf(stderr, "xscope_ep_set_record_cb failed\n");
    exit(1);
  }

  if (xscope_ep_connect("localhost", port_str) != XSCOPE_EP_SUCCESS) {
    exit(1);
  }

  printf("connected to server at port %d\n", port);

  /* wait for xSCOPE probe registration */
  while (probe_id == -1) {
    usleep(100);
  }
}

unsigned num_commands = 0;

void do_set_command(void)
{
  struct command c;
  unsigned char *cb;
  unsigned char payload[1];
  int len;

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

  if (xscope_ep_request_upload(len, cb) != XSCOPE_EP_SUCCESS)
    printf("xscope_ep_request_upload failed\n");

  num_commands++;
}

void do_get_command(void)
{
  struct command c;
  unsigned char *cb;
  int len;

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

  record_count = 0;

  if (xscope_ep_request_upload(len, cb) != XSCOPE_EP_SUCCESS)
    printf("xscope_ep_request_upload failed\n");

  /* wait for response on xSCOPE probe */
  while (record_count == 0) {
    usleep(100);
  }

  num_commands++;
}

void shutdown(void)
{
  /* xSCOPE disconnect hangs (SIGINT propagated to pthread?) */
  exit(0);
}

int main(void)
{
  int i;

  signals_init();
  init_xscope(10101);
  signals_setup_int(shutdown);

  while (1) {
    for (i = 0; i < 4; i++) {
      do_set_command();
      usleep(100000);
      do_get_command();
      sleep(1);
    }
  }

  return 0;
}
