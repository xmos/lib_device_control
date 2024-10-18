// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"
#include "control_transport_shared.h"

#include "control_host_support.h"

void test_usb(client interface control i[1])
{
  uint16_t windex, wvalue, wlength;
  uint8_t request_data[64];
  control_version_t version;
  control_ret_t ret;

  control_usb_fill_header(&windex, &wvalue, &wlength,
    CONTROL_SPECIAL_RESID, CONTROL_GET_VERSION, sizeof(control_version_t));

#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
  ret = control_process_usb_get_request(windex, wvalue, wlength, request_data, i);
#pragma warning disable
  memcpy(&version, request_data, sizeof(control_version_t));

  if (ret != CONTROL_SUCCESS) {
    printf("ERROR - USB processing function returned %d\n", ret);
    exit(1);
  }
  if (version != CONTROL_VERSION) {
    printf("ERROR - USB returned control version 0x%X, expected 0x%X\n", version, CONTROL_VERSION);
    exit(1);
  }
}

void test_i2c(client interface control i[1])
{
  uint8_t buf[I2C_TRANSACTION_MAX_BYTES];
  control_version_t version;
  control_ret_t ret;
  uint8_t data[8];
  size_t len;
  int j;

  len = control_build_i2c_data(buf, CONTROL_SPECIAL_RESID,
    CONTROL_GET_VERSION, data, sizeof(control_version_t));
  ret = CONTROL_SUCCESS;

#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
  ret |= control_process_i2c_write_start(i);
  for (j = 0; j < len; j++) {
    ret |= control_process_i2c_write_data(buf[j], i);
  }
  ret |= control_process_i2c_read_start(i);
  for (j = 0; j < sizeof(control_version_t); j++) {
    ret |= control_process_i2c_read_data(data[j], i);
  }

  memcpy(&version, data, sizeof(control_version_t));
  ret |= control_process_i2c_stop(i);
#pragma warning enable

  if (ret != CONTROL_SUCCESS) {
    printf("ERROR - I2C processing functions returned %d\n", ret);
    exit(1);
  }
  if (version != CONTROL_VERSION) {
    printf("ERROR - I2C returned control version 0x%X, expected 0x%X\n", version, CONTROL_VERSION);
    exit(1);
  }
}

void test_spi(client interface control i[1])
{
  uint8_t buf[SPI_TRANSACTION_MAX_BYTES];
  control_version_t version;
  control_ret_t ret = CONTROL_SUCCESS;
  uint8_t data[8];
  size_t len = 0;
  uint32_t data_32bit = 0;
  uint8_t dummy_byte = 0;
  int j = 0;

  // Prepare message header and payload
  len = control_build_spi_data(buf, CONTROL_SPECIAL_RESID,
    CONTROL_GET_VERSION, (uint8_t*) data, sizeof(control_version_t));

#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
  // Send message information in a write transaction
  for (j = 0; j < len; j++) {
    ret |= control_process_spi_master_supplied_data(buf[j], SPI_TRANSFER_SIZE_BITS, i);
    ret |= control_process_spi_master_requires_data(data_32bit, i);
  }
  ret |= control_process_spi_master_ends_transaction(i);

  // Read back value in a read transaction
  for (j = 0; j < sizeof(control_version_t); j++) {
    ret |= control_process_spi_master_supplied_data(dummy_byte, SPI_TRANSFER_SIZE_BITS, i);
    ret |= control_process_spi_master_requires_data(data_32bit, i);
    memcpy(&data[j], &data_32bit, sizeof(uint8_t));
  }
  memcpy(&version, data, sizeof(control_version_t));

  ret |= control_process_spi_master_ends_transaction(i);
#pragma warning disable

  if (ret != CONTROL_SUCCESS) {
    printf("ERROR - SPI processing functions returned %d\n", ret);
    exit(1);
  }
  if (version != CONTROL_VERSION) {
    printf("ERROR - SPI returned control version 0x%X, expected 0x%X\n", version, CONTROL_VERSION);
    exit(1);
  }
}

void test_xscope(client interface control i[1])
{
  uint32_t buf[64];
  struct control_xscope_response *resp;
  control_version_t version;
  size_t len, len2;
  control_ret_t ret;

  len = control_xscope_create_upload_buffer(buf,
    CONTROL_GET_VERSION, CONTROL_SPECIAL_RESID,
    NULL, sizeof(control_version_t));

  ret = control_process_xscope_upload((uint8_t*)buf, sizeof(buf), len, len2, i);
  resp = (struct control_xscope_response*)buf;
  version = *(control_version_t*)(resp + 1);

  if (ret != CONTROL_SUCCESS) {
    printf("ERROR - xSCOPE processing function returned %d\n", ret);
    exit(1);
  }
  if (resp->ret != CONTROL_SUCCESS) {
    printf("ERROR - xSCOPE response return code %d\n", resp->ret);
    exit(1);
  }
  else if (version != CONTROL_VERSION) {
    printf("ERROR - xSCOPE returned control version 0x%X, expected 0x%X\n", version, CONTROL_VERSION);
    exit(1);
  }
}

void dummy_user_task(server interface control i)
{
  // nothing
}

int main(void)
{
  interface control i[1];
  par {
    {
      control_init();
      test_i2c(i);
      test_spi(i);
      test_usb(i);
      test_xscope(i);
      printf("Success!\n");

      exit(0);
    }
    dummy_user_task(i[0]);
    { delay_microseconds(1000);
      printf("ERROR - test timeout\n");
      exit(1);
    }
  }
  return 0;
}
