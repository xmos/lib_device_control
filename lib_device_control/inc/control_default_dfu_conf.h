// Copyright 2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef CONTROL_DEFAULT_DFU_CONF_H
#define CONTROL_DEFAULT_DFU_CONF_H

#ifdef __control_dfu_conf_h_exists__
#include "control_dfu_conf.h"
#endif

/** Resource ID for DFU */
#ifndef RESOURCE_ID_DFU
#define RESOURCE_ID_DFU 0xD0
#endif

#ifndef CONTROL_APP_DFU
#define CONTROL_APP_DFU 0
#endif

#endif // CONTROL_DEFAULT_DFU_CONF_H
