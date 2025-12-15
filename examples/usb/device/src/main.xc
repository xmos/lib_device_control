// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <platform.h>
#include <assert.h>
#include <xscope.h>
#include <stdio.h>
#include <stdint.h>

#include "endpoint0.h"
#include "control.h"
#include "app.h"
#include "xud_device.h"

#define DEBUG_UNIT DEVICE
#include "debug_print.h"

/* USB Endpoint Defines */
#define XUD_EP_COUNT_OUT   1    //Includes EP0 (1 OUT EP0)
#define XUD_EP_COUNT_IN    1    //Includes EP0 (1 IN EP0)


XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};

int main(void)
{
  chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
  interface control i_control[1];
  par {
    on USB_TILE: par {
      Endpoint0(c_ep_out[0], c_ep_in[0], i_control);
      XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                      null, epTypeTableOut, epTypeTableIn,
                      XUD_SPEED_HS, XUD_PWR_BUS);
    }
    on tile[0]: par {
      app(i_control[0]);
    }
  }
  return 0;
}
