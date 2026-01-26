// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef APP_H
#define APP_H

#include "control.h"

/* Arbitrary resource ID assigned. Could be anything from 0x01 to 0xff */
#define RESOURCE_ID 0x12

void app(server interface control i_control);

#endif // APP_H
