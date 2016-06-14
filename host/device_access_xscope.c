// Copyright (c) 2016, XMOS Ltd, All rights reserved
#if USE_XSCOPE

#include <stdio.h>
#include <string.h>
#include <signal.h>
#include <assert.h>
#include <stdlib.h>
#include <stdint.h>
#include "xscope_endpoint.h"
#include "control_host.h"
#include "control_host_support.h"
#include "util.h"

//#define DBG(x) x
#define DBG(x)

#define UNUSED_PARAMETER(x) (void)(x)

static unsigned int probe_id = 0xffffffff;
static size_t record_count = 0;
static struct control_xscope_response last_response;
static unsigned num_commands = 0;

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
    DBG(printf("registered probe %d\n", id));
  }
}

void xscope_print(unsigned long long timestamp,
                  unsigned int length,
                  unsigned char *data) {
  if (length) {
    for (int i = 0; i < length; i++) {
      printf("%c", *(&data[i]));
    }
  }
}

void record_callback(unsigned int id, unsigned long long timestamp,
  unsigned int length, unsigned long long dataval, unsigned char *databytes)
{
  UNUSED_PARAMETER(timestamp);
  UNUSED_PARAMETER(dataval);

  if (id == probe_id) {
    if (length > sizeof(struct control_xscope_response))
      length = sizeof(struct control_xscope_response);

    memcpy((void*)&last_response, databytes, length);

    record_count++;
  }
}

control_ret_t control_init_xscope(const char *host_str, const char *port_str)
{
  if (xscope_ep_set_print_cb(xscope_print) != XSCOPE_EP_SUCCESS) {
    fprintf(stderr, "xscope_ep_set_print_cb failed\n");
    return CONTROL_ERROR;
  }

  if (xscope_ep_set_register_cb(register_callback) != XSCOPE_EP_SUCCESS) {
    fprintf(stderr, "xscope_ep_set_register_cb failed\n");
    return CONTROL_ERROR;
  }

  if (xscope_ep_set_record_cb(record_callback) != XSCOPE_EP_SUCCESS) {
    fprintf(stderr, "xscope_ep_set_record_cb failed\n");
    return CONTROL_ERROR;
  }

  if (xscope_ep_connect(host_str, port_str) != XSCOPE_EP_SUCCESS) {
    return CONTROL_ERROR;
  }

  DBG(printf("connected to server at port %s\n", port_str));

  // wait for xSCOPE probe registration
  while (probe_id == -1) {
    pause_short();
  }

  return CONTROL_SUCCESS;
}

control_ret_t control_query_version(control_version_t *version)
{
  struct control_xscope_packet p;

  unsigned *b = (unsigned*)&p;
  size_t len = control_xscope_create_upload_buffer(b,
    CONTROL_GET_VERSION, CONTROL_SPECIAL_RESID, NULL, sizeof(control_version_t));

  DBG(printf("%d: send version command: ", num_commands));
  DBG(print_bytes((unsigned char*)b, len));

  record_count = 0;

  if (xscope_ep_request_upload(len, (unsigned char*)b) != XSCOPE_EP_SUCCESS) {
    printf("xscope_ep_request_upload failed\n");
    return CONTROL_ERROR;
  }

  while (record_count == 0) { // wait for response on xSCOPE probe
    pause_short();
  }

  DBG(printf("response: "));
  DBG(print_bytes((uint8_t*)&last_response, XSCOPE_HEADER_BYTES + last_response.payload_len));

  *version = *(control_version_t*)&last_response.payload;

  num_commands++;
  return CONTROL_SUCCESS + last_response.ret;
}

control_ret_t
control_write_command(control_resid_t resid, control_cmd_t cmd,
                      const uint8_t payload[], size_t payload_len)
{
  struct control_xscope_packet p;

  unsigned *b = (unsigned*)&p;
  size_t len = control_xscope_create_upload_buffer(b,
    CONTROL_CMD_SET_WRITE(cmd), resid, payload, payload_len);

  DBG(printf("%u: send write command: ", num_commands));
  DBG(print_bytes((unsigned char*)b, len));

  record_count = 0;

  if (xscope_ep_request_upload(len, (unsigned char*)b) != XSCOPE_EP_SUCCESS) {
    printf("xscope_ep_request_upload failed\n");
    return CONTROL_ERROR;
  }

  while (record_count == 0) { // wait for response on xSCOPE probe
    pause_short();
  }

  DBG(printf("response: "));
  DBG(print_bytes((uint8_t*)&last_response, XSCOPE_HEADER_BYTES));

  num_commands++;
  return CONTROL_SUCCESS + last_response.ret;
}

control_ret_t
control_read_command(control_resid_t resid, control_cmd_t cmd,
                     uint8_t payload[], size_t payload_len)
{
  struct control_xscope_packet p;

  unsigned *b = (unsigned*)&p;
  size_t len = control_xscope_create_upload_buffer(b,
    CONTROL_CMD_SET_READ(cmd), resid, NULL, payload_len);

  DBG(printf("%d: send read command: ", num_commands));
  DBG(print_bytes((unsigned char*)b, len));

  record_count = 0;

  if (xscope_ep_request_upload(len, (unsigned char*)b) != XSCOPE_EP_SUCCESS) {
    printf("xscope_ep_request_upload failed\n");
    return CONTROL_ERROR;
  }

  while (record_count == 0) { // wait for response on xSCOPE probe
    pause_short();
  }

  DBG(printf("response: "));
  DBG(print_bytes((uint8_t*)&last_response, XSCOPE_HEADER_BYTES + last_response.payload_len));

  // ignore returned payload length, use one supplied in request
  memcpy(payload, last_response.payload, payload_len);

  num_commands++;
  return CONTROL_SUCCESS + last_response.ret;
}

control_ret_t control_cleanup_xscope(void)
{
  #ifdef WIN32
  // Bug in 14.1 means this is required on Windows but not OSX
  xscope_ep_disconnect();
  #endif
  // xSCOPE disconnect hangs (SIGINT propagated to pthread?)
  exit(0);

  return CONTROL_SUCCESS;
}

#endif // USE_XSCOPE
