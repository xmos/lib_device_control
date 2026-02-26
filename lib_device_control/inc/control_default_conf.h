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

#ifndef USE_USB
#define USE_USB 0
#endif

#ifndef USE_I2C
#define USE_I2C 0
#endif

#ifndef USE_SPI
#define USE_SPI 0
#endif

#ifndef USE_XSCOPE
#define USE_XSCOPE 0
#endif

#if (CONTROL_TEST_HEADLESS + USE_USB + USE_I2C + USE_SPI + USE_XSCOPE) > 1
#error "Multiple USB transport types defined. Please ensure only one of USE_USB, USE_I2C, USE_SPI, or USE_XSCOPE is set to 1."
#elif ((CONTROL_TEST_HEADLESS + USE_USB + USE_I2C + USE_SPI + USE_XSCOPE) == 0)
#error "No USB transport type defined. Please ensure one of USE_USB, USE_I2C, USE_SPI, or USE_XSCOPE is set to 1."
#endif


#endif // CONTROL_DEFAULT_CONF_H
