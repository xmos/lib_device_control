// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdio.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif
#include <signal.h>
#include <stdlib.h>
#include <stdint.h>
#include "xscope_endpoint.h"
#include "control_host.h"
#include "util.h"
#include "signals.h"
#include "resource.h"

#define UNUSED_PARAMETER(x) (void)(x)

#ifdef _WIN32

static void pause_short()
{
  Sleep(1);
}

static void pause_long()
{
  Sleep(1000);
}

#else

static void pause_short()
{
  usleep(100000);
}

static void pause_long()
{
  sleep(1);
}

#endif // _WIN32

static unsigned int probe_id = 0xffffffff;
static int record_count = 0;

void register_callback(unsigned int id, unsigned int type,
  unsigned int r, unsigned int g, unsigned int b,
  unsigned char *name, unsigned char *unit,
  unsigned int data_type, unsigned char *data_name)
{
  UNUSED_PARAMETER(type);
  UNUSED_PARAMETER(r);
  UNUSED_PARAMETER(g);
  UNUSED_PARAMETER(b);
  UNUSED_PARAMETER(unit);
  UNUSED_PARAMETER(data_type);
  UNUSED_PARAMETER(data_name);

  if (strcmp((char*)name, XSCOPE_CONTROL_PROBE) == 0) {
    probe_id = id;
    printf("registered probe %d\n", id);
  }
}

void record_callback(unsigned int id, unsigned long long timestamp,
  unsigned int length, unsigned long long dataval, unsigned char *databytes)
{
  UNUSED_PARAMETER(timestamp);
  UNUSED_PARAMETER(dataval);

  struct control_xscope_probe *p;

  if (id == probe_id) {
    p = (struct control_xscope_probe*)databytes;
    /* no parsing, just print raw bytes */

    printf("read data returned: ");
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
    pause_short();
  }
}

unsigned num_commands = 0;

void do_write_command(void)
{
  struct control_xscope_packet p;
  unsigned *b;
  unsigned char payload[1];
  size_t len;

  b = (unsigned*)&p;
  payload[0] = 1;
  len = control_xscope_create_upload_buffer(b,
    CONTROL_CMD_SET_WRITE(0), resource_id, payload, sizeof(payload));

  printf("%u: send write command: ", num_commands);
  print_bytes((unsigned char*)b, len);

  if (xscope_ep_request_upload(len, (unsigned char*)b) != XSCOPE_EP_SUCCESS) {
    printf("xscope_ep_request_upload failed\n");
  }

  num_commands++;
}

void do_read_command(void)
{
  struct control_xscope_packet p;
  unsigned *b;
  size_t len;

  b = (unsigned*)&p;
  len = control_xscope_create_upload_buffer(b,
    CONTROL_CMD_SET_READ(0), resource_id, NULL, 4);

  printf("%d: send read command: ", num_commands);
  print_bytes((unsigned char*)b, len);

  record_count = 0;

  if (xscope_ep_request_upload(len, (unsigned char*)b) != XSCOPE_EP_SUCCESS) {
    printf("xscope_ep_request_upload failed\n");
  }

  /* wait for response on xSCOPE probe */
  while (record_count == 0) {
    pause_short();
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
      do_write_command();
      pause_short();
      do_read_command();
      pause_long();
    }
  }

  return 0;
}
