// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef __app_h__
#define __app_h__

#include "control.h"

#define RESOURCE_ID 0x12

void app(server interface control i_control, client interface mabs_led_button_if i_leds_buttons);

#endif // __app_h__
