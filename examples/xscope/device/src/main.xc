// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <platform.h>
#include <stdio.h>
#include <assert.h>
#include <timer.h>
#include <xscope.h>
#include <stdint.h>
#include "control.h"
#include "app.h"

#include "transport_xscope.h"

int main(void)
{
  chan c_xscope;
  interface control i_control[1];

  par {
    xscope_host_data(c_xscope);
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
    on tile[0]: xscope_control_client(c_xscope, i_control);
#pragma warning enable
    on tile[0]: app(i_control[0]);
  }
  return 0;
}
