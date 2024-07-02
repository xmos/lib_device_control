// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef APP_H_
#define APP_H_

#include "control.h"

#define RESOURCE_ID 0x12

void app(server interface control i_control, client interface mabs_led_button_if i_leds_buttons);

#endif // APP_H_
