# This exists to test the Makefile build of lib_dfu

TARGET = xk-voice-l71.xn

APP_NAME =

XCC_FLAGS  = -O3 -mno-dual-issue -g -report ../config.xscope

USED_MODULES = lib_device_control lib_i2c(>=6.4.1)

#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
