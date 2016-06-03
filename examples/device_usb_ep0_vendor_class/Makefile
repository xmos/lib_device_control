TARGET = mic_array_ref.xn
MODULE_LIBRARIES = xud_x200
XCC_FLAGS = -Wall -g -O3 -DXUD_SERIES_SUPPORT=4 -DUSB_TILE=tile[1]
USED_MODULES = lib_device_control lib_usb
XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
