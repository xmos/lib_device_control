// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <platform.h>
#include <stdio.h>
#include <assert.h>
#include <timer.h>
#include <xscope.h>
#include <stdint.h>
#include "control.h"
#include "app.h"

[[combinable]]
void xscope_client(chanend c_xscope, client interface control i_control[1])
{
  uint8_t buffer[256]; /* 256 bytes from xscope.h */
  int num_bytes_read;
  unsigned return_size;

  control_init();
  control_register_resources(i_control, 1);

  xscope_connect_data_from_host(c_xscope);

  printf("xSCOPE server connected\n");

  while (1) {
    select {
      case xscope_data_from_host(c_xscope, buffer, num_bytes_read):
        control_process_xscope_upload(buffer, sizeof(buffer), num_bytes_read, return_size, i_control);
        if (return_size > 0) {
          xscope_core_bytes(0, return_size, buffer);
        }
        break;
    }
  }
}

int main(void)
{
  chan c_xscope;
  interface control i_control[1];

  par {
    xscope_host_data(c_xscope);
    on tile[0]: xscope_client(c_xscope, i_control);
    on tile[0]: app(i_control[0]);
  }
  return 0;
}
