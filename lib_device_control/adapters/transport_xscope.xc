// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "control.h"
#if CONTROL_USE_XSCOPE

#include "transport_xscope.h"

#include <platform.h>
#include <xscope.h>

// XSCOPE transport client processing function, this passes XSCOPE data to the control interface.
//
// To include this file in the build, define CONTROL_USE_XSCOPE as 1, in control_conf.h

#define DEBUG_UNIT TRANSPORT
#include "debug_print.h"

void xscope_control_client(chanend c_xscope, client interface control i_control[CONTROL_INTERFACES_NUM])
{
  uint8_t buffer[256]; /* 256 bytes from xscope.h */
  int num_bytes_read;

  control_init();
  control_register_resources(i_control, CONTROL_INTERFACES_NUM);

  xscope_connect_data_from_host(c_xscope);

  debug_printf("XSCOPE server connected\n");

  while (1) {
    select {
      case xscope_data_from_host(c_xscope, buffer, num_bytes_read):
        unsigned return_size;
        control_process_xscope_upload(buffer, sizeof(buffer), num_bytes_read, return_size, i_control);
        if (return_size > 0) {
          xscope_core_bytes(0, return_size, buffer);
        }
        break;
    }
  }
}

#endif // CONTROL_USE_XSCOPE
