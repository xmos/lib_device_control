// Copyright 2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef DFU_CONTROL_SERVER_H
#define DFU_CONTROL_SERVER_H

#include <xccompat.h>

#include "control.h"

void dfu_control_server(SERVER_INTERFACE(control, dfu_control_interface));

#endif // DFU_CONTROL_SERVER_H
