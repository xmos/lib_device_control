// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef APP_DEV_H_
#define APP_DEV_H_

#include "i2c.h"
#include "control.h"

void i2c_client(server i2c_slave_callback_if i_i2c, client interface control i_control[1]);
void app_device(server interface control i_control);

#endif // APP_DEV_H_
