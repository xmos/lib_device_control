TARGET = mic_array_ref.xn
MODULE_LIBRARIES = xud_x200
XCC_FLAGS = -Wall -g -O3 -report -fsubword-select -DTEST_MODE_SUPPORT -Xmapper --wno226 -DXUD_SERIES_SUPPORT=4 -DUSB_TILE=tile[1]
USED_MODULES = lib_control module_usb_shared module_usb_device module_xud module_usb_tile_support
XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
