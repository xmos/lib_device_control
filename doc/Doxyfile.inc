# This file provides overrides to the Doxyfile configuration

PROJECT_NAME            = lib_device_control
PROJECT_BRIEF           = "Device Control for xcore"

INPUT                   = ../lib_device_control/api ../lib_device_control/inc  ../host/api ../host/inc

EXCLUDE_PATTERNS        = libusb.h

PREDEFINED              = C_API= EXTERN_C= slave= __DOXYGEN__=1 interface= __attribute__(x)=
