TARGET = XVF3610_Q60A.xn
#TARGET = XCORE-VISION-EXPLORER.xn
XCC_FLAGS = -Wall -g -O3 -report
USED_MODULES = lib_device_control(>=3.0.0) lib_xud(>=2.3.0)
XMOS_MAKE_PATH ?= ../..

#The following avoids hostapp files being scanned and compiled
SOURCE_DIRS = src
INCLUDE_DIRS = src

include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
