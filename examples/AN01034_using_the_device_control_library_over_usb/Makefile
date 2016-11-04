TARGET = MIC-ARRAY-1V0.xn
MODULE_LIBRARIES = xud_x200
XCC_FLAGS = -Wall -g -O3 -DXUD_SERIES_SUPPORT=4 -DUSB_TILE=tile[1] -report
USED_MODULES = lib_device_control(>=3.0.0) lib_usb(>=3.1.2) lib_mic_array_board_support(>=2.1.0)
XMOS_MAKE_PATH ?= ../..
#The following avoids hostapp files being scanned and compiled
SOURCE_DIRS = src
INCLUDE_DIRS = src 
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
