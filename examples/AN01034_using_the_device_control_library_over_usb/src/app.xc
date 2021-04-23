// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include "control.h"
#include "mic_array_board_support.h"
#include "app.h"

void app(server interface control i_control, client interface mabs_led_button_if i_leds_buttons)
{
  printf("started\n");

  while (1) {
    select {
      case i_control.register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                                        unsigned &num_resources):
        resources[0] = RESOURCE_ID;
        num_resources = 1;
        break;

      case i_control.write_command(control_resid_t resid, control_cmd_t cmd,
                                   const uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret:
        printf("W: %d %d %d,", resid, cmd, payload_len);
        for (int i = 0; i < payload_len; i++) {
          printf(" %02x", payload[i]);
        }
        printf("\n");
        if (resid != RESOURCE_ID) {
          printf("unrecognised resource ID %d\n", resid);
          ret = CONTROL_ERROR;
          break;
        }
        for (int i = 0; i < MIC_BOARD_SUPPORT_LED_COUNT; i++){
          if (i < payload[0]) i_leds_buttons.set_led_brightness(i, 255);
          else i_leds_buttons.set_led_brightness(i, 0);
        }
        ret = CONTROL_SUCCESS;
        break;

      case i_control.read_command(control_resid_t resid, control_cmd_t cmd,
                                  uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret:
        printf("R: %d %d %d\n", resid, cmd, payload_len);
        if (resid != RESOURCE_ID) {
          printf("unrecognised resource ID %d\n", resid);
          ret = CONTROL_ERROR;
          break;
        }
        if (payload_len != 2) {
          printf("expecting 2 read bytes, not %d\n", payload_len);
          ret = CONTROL_ERROR;
          break;
        }
        unsigned button;
        mabs_button_state_t button_state;
        i_leds_buttons.get_button_event(button, button_state);
        payload[0] = button;
        payload[1] = button_state;
        ret = CONTROL_SUCCESS;
        break;
    }
  }
}
