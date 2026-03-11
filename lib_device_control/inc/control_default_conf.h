// Copyright 2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef CONTROL_DEFAULT_CONF_H
#define CONTROL_DEFAULT_CONF_H

#ifdef __control_conf_h_exists__
#include "control_conf.h"
#endif

#ifndef CONTROL_INTERFACES_NUM
#define CONTROL_INTERFACES_NUM 1
#endif

#if CONTROL_INTERFACES_NUM <= 0
#error "CONTROL_INTERFACES_NUM must be at least 1"
#endif

#ifndef CONTROL_USE_USB
#define CONTROL_USE_USB 0
#endif

#ifndef CONTROL_USE_I2C
#define CONTROL_USE_I2C 0
#endif

#ifndef CONTROL_USE_SPI
#define CONTROL_USE_SPI 0
#endif

#ifndef CONTROL_USE_XSCOPE
#define CONTROL_USE_XSCOPE 0
#endif

#if (CONTROL_TEST_HEADLESS + CONTROL_USE_USB + CONTROL_USE_I2C + CONTROL_USE_SPI + CONTROL_USE_XSCOPE) > 1
#error "Multiple transport types defined. Please ensure only one of CONTROL_USE_USB, CONTROL_USE_I2C, CONTROL_USE_SPI, or CONTROL_USE_XSCOPE is set to 1."
#elif ((CONTROL_TEST_HEADLESS + CONTROL_USE_USB + CONTROL_USE_I2C + CONTROL_USE_SPI + CONTROL_USE_XSCOPE) == 0)
#error "No transport type defined. Please ensure one of CONTROL_USE_USB, CONTROL_USE_I2C, CONTROL_USE_SPI, or CONTROL_USE_XSCOPE is set to 1."
#endif

/** Resource ID for DFU */
#ifndef RESOURCE_ID_DFU
#define RESOURCE_ID_DFU 0xD0
#endif

/* When enabled, will include the control DFU application server in the build */
#ifndef CONTROL_APP_DFU
#define CONTROL_APP_DFU 0
#endif

#endif // CONTROL_DEFAULT_CONF_H
