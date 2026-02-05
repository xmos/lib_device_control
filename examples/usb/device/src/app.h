// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef APP_H
#define APP_H

#include <xccompat.h>
#include "control.h"

void app(SERVER_INTERFACE(control, i_control));

#endif // APP_H
