// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#if USE_XSCOPE

#include <stdio.h>
#include <string.h>
#include <signal.h>
#include <assert.h>
#ifndef _WIN32
#include <stdbool.h>
#endif
#include <stdlib.h>
#include <stdint.h>
#include "xscope_endpoint.h"
#include "control_host.h"
#include "control_host_support.h"
#include "util.h"

//#define DBG(x) x
#define DBG(x)
#define PRINT_ERROR(...)   fprintf(stderr, "Error  : " __VA_ARGS__)

#define UNUSED_PARAMETER(x) (void)(x)

static volatile unsigned int probe_id = 0xffffffff;
static volatile size_t record_count = 0;
static unsigned char *last_response = NULL;
static struct control_xscope_response *last_response_struct = NULL;
static unsigned last_response_length = 0;
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
  UNUSED_PARAMETER(timestamp);

  if (length) {
    for (unsigned i = 0; i < length; i++) {
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
    if (last_response != NULL) {
      free(last_response);
    }
    last_response = (unsigned char*)malloc(length);
    last_response_struct = (struct control_xscope_response*)last_response;
    last_response_length = length;
    memcpy(last_response, databytes, length);
    
    record_count++;
  }
}

control_ret_t control_init_xscope(const char *host_str, const char *port_str)
{
  if (xscope_ep_set_print_cb(xscope_print) != XSCOPE_EP_SUCCESS) {
    PRINT_ERROR("xscope_ep_set_print_cb failed\n");
    return CONTROL_ERROR;
  }

  if (xscope_ep_set_register_cb(register_callback) != XSCOPE_EP_SUCCESS) {
    PRINT_ERROR("xscope_ep_set_register_cb failed\n");
    return CONTROL_ERROR;
  }

  if (xscope_ep_set_record_cb(record_callback) != XSCOPE_EP_SUCCESS) {
    PRINT_ERROR("xscope_ep_set_record_cb failed\n");
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
  unsigned b[XSCOPE_UPLOAD_MAX_WORDS];

  size_t len = control_xscope_create_upload_buffer(b,
    CONTROL_GET_VERSION, CONTROL_SPECIAL_RESID, NULL, sizeof(control_version_t));

  DBG(printf("%d: send version command: ", num_commands));
  DBG(print_bytes((unsigned char*)b, len));

  record_count = 0;

  if (xscope_ep_request_upload(len, (unsigned char*)b) != XSCOPE_EP_SUCCESS) {
    PRINT_ERROR("xscope_ep_request_upload failed\n");
    return CONTROL_ERROR;
  }
  
  // wait for response on xSCOPE probe
  while (record_count == 0) {
    pause_short();
  }

  DBG(printf("response: "));
  DBG(print_bytes(last_response, last_response_length));

  *version = *(control_version_t*)(last_response + sizeof(struct control_xscope_response));

  num_commands++;
  return CONTROL_SUCCESS + last_response_struct->ret;
}

/*
 * xSCOPE has an internally hardcoded limit of 256 bytes. Where it passes
 * the xSCOPE endpoint API upload command to xGDB server, it truncates
 * payload to 256 bytes.
 *
 * Let's have host code check payload size here. No additional checks on
 * device side. Device will need a 256-byte buffer to receive from xSCOPE
 * service.
 *
 * No checking of read data which goes in other direction, device to host.
 * This is xSCOPE probe bytes API, which has no limit.
 */
static bool upload_len_exceeds_xscope_limit(size_t len)
{
  if (len > XSCOPE_UPLOAD_MAX_BYTES) {
    PRINT_ERROR("Upload of %zd bytes requested\n", len);
    PRINT_ERROR("Maximum upload size is %d\n", XSCOPE_UPLOAD_MAX_BYTES);
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
  unsigned b[XSCOPE_UPLOAD_MAX_WORDS];

  size_t len = control_xscope_create_upload_buffer(b,
    CONTROL_CMD_SET_WRITE(cmd), resid, payload, payload_len);

  if (upload_len_exceeds_xscope_limit(len))
    return CONTROL_DATA_LENGTH_ERROR;

  DBG(printf("%u: send write command: ", num_commands));
  DBG(print_bytes((unsigned char*)b, len));

  record_count = 0;

  if (xscope_ep_request_upload(len, (unsigned char*)b) != XSCOPE_EP_SUCCESS) {
    PRINT_ERROR("xscope_ep_request_upload failed\n");
    return CONTROL_ERROR;
  }
  // wait for response on xSCOPE probe
  while (record_count == 0) { 
    pause_short();
  }

  DBG(printf("response: "));
  DBG(print_bytes(last_response, XSCOPE_HEADER_BYTES));

  num_commands++;
  return CONTROL_SUCCESS + last_response_struct->ret;
}

control_ret_t
control_read_command(control_resid_t resid, control_cmd_t cmd,
                     uint8_t payload[], size_t payload_len)
{
  unsigned b[XSCOPE_UPLOAD_MAX_WORDS];

  size_t len = control_xscope_create_upload_buffer(b,
    CONTROL_CMD_SET_READ(cmd), resid, NULL, payload_len);

  DBG(printf("%d: send read command: ", num_commands));
  DBG(print_bytes((unsigned char*)b, len));

  record_count = 0;

  if (xscope_ep_request_upload(len, (unsigned char*)b) != XSCOPE_EP_SUCCESS) {
    PRINT_ERROR("xscope_ep_request_upload failed\n");
    return CONTROL_ERROR;
  }
  
  // wait for response on xSCOPE probe
  while (record_count == 0) {
    pause_short();
  }

  DBG(printf("response: "));
  DBG(print_bytes(last_response, last_response_length));

  // ignore returned payload length, use one supplied in request
  memcpy(payload, last_response + sizeof(struct control_xscope_response), payload_len);

  num_commands++;
  return CONTROL_SUCCESS + last_response_struct->ret;
}

control_ret_t control_cleanup_xscope(void)
{
  #ifdef _WIN32
  // Bug in 14.1 means this is required on Windows but not OSX
  xscope_ep_disconnect();
  #endif
  // xSCOPE disconnect hangs (SIGINT propagated to pthread?)

  return CONTROL_SUCCESS;
}

#endif // USE_XSCOPE
