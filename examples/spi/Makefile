TARGET = XK_VOICE_L71.xn
XCC_FLAGS = -Wall -g -O3 -DSPI_TILE=0 -report
USED_MODULES = lib_device_control(>=3.0.0) lib_spi
XMOS_MAKE_PATH ?= ../..
#The following avoids hostapp files being scanned and compiled
SOURCE_DIRS = src
INCLUDE_DIRS = src
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
