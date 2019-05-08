APP_NAME = device_control
TARGET = MIC-ARRAY-1V0.xn
MODULE_LIBRARIES = xud_x200
XCC_FLAGS = -Wall -g -O2 -DXUD_SERIES_SUPPORT=4 -DUSB_TILE=tile[1]
INCLUDE_DIRS = .
USED_MODULES = lib_device_control(>=3.0.0) lib_mic_array_board_support(>=2.2.0) lib_usb(>=3.1.2)
SOURCE_DIRS = src # ignore host directory
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
