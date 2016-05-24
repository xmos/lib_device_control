// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>
#include <stdint.h>
#include "xscope_endpoint.h"
#include "control_host.h"
#include "util.h"
#include "signals.h"
#include "resource.h"

int probe_id = -1;
int record_count = 0;

void register_callback(unsigned int id, unsigned int type,
  unsigned int r, unsigned int g, unsigned int b,
  unsigned char *name, unsigned char *unit,
  unsigned int data_type, unsigned char *data_name)
{
  if (strcmp((char*)name, XSCOPE_PROBE_NAME) == 0) {
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

void do_write_command(void)
{
  struct control_xscope_upload c;
  unsigned *cb;
  unsigned char payload[1];
  size_t len;

  cb = (void*)&c;
  payload[0] = 1;
  len = control_create_xscope_upload_buffer(cb,
    CONTROL_CMD_SET_WRITE(0), RESOURCE_ID, payload, 1);

  printf("%u: send write command: ", num_commands);
  print_bytes((unsigned char*)cb, len);

  if (xscope_ep_request_upload(len, (unsigned char*)cb) != XSCOPE_EP_SUCCESS)
    printf("xscope_ep_request_upload failed\n");

  num_commands++;
}

void do_read_command(void)
{
  struct control_xscope_upload c;
  unsigned *cb;
  size_t len;

  cb = (void*)&c;
  len = control_create_xscope_upload_buffer(cb,
    CONTROL_CMD_SET_READ(0), RESOURCE_ID, NULL, 4);

  printf("%d: send read command: ", num_commands);
  print_bytes((unsigned char*)cb, len);

  record_count = 0;

  if (xscope_ep_request_upload(len, (unsigned char*)cb) != XSCOPE_EP_SUCCESS)
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
      do_write_command();
      usleep(100000);
      do_read_command();
      sleep(1);
    }
  }

  return 0;
}
