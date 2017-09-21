// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved
#ifndef __app_h__
#define __app_h__

#include "control.h"

/* Arbitrary resource ID assigned. Could be anything from 0x01 to 0xff */
#define RESOURCE_ID 0x12

void app(server interface control i_control, client interface mabs_led_button_if i_leds_buttons);

#endif // __app_h__
