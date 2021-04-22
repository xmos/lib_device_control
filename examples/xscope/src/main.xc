// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <platform.h>
#include <stdio.h>
#include <assert.h>
#include <timer.h>
#include <xscope.h>
#include <stdint.h>
#include "control.h"
#include "mic_array_board_support.h"
#include "app.h"

on tile[0]: in port p_buttons =  MIC_BOARD_SUPPORT_BUTTON_PORTS;

//TODO use MIC_BOARD_SUPPORT_LED_PORTS in post 2.2.0 lib_mic_array_board_support
on tile[0]: mabs_led_ports_t p_leds = {
  PORT_LED0_TO_7, PORT_LED8, PORT_LED9, PORT_LED10_TO_12, XS1_PORT_1P
};

void xscope_user_init(void)
{
  xscope_register(1, XSCOPE_CONTINUOUS, XSCOPE_CONTROL_PROBE, XSCOPE_INT, "byte");

  /* without "xscope_config_io(XSCOPE_IO_BASIC)",
   * JTAG is used for console I/O (bug 17287)
   */
}

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
  interface mabs_led_button_if i_leds_buttons[1];

  par {
    xscope_host_data(c_xscope);
    on tile[0]: xscope_client(c_xscope, i_control);
    on tile[0]: app(i_control[0], i_leds_buttons[0]);
    on tile[0]: mabs_button_and_led_server(i_leds_buttons, 1, p_leds, p_buttons);
  }
  return 0;
}
