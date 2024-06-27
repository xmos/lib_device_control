TARGET = vfspk_base.xn
XCC_FLAGS = -fxscope -Wall -g -O2 -report -DUSE_XSCOPE=1
#XCC_FLAGS += -D ERRONEOUS_DEVICE
USED_MODULES = lib_device_control lib_mic_array_board_support
XMOS_MAKE_PATH ?= ../..
# Ignore host dir
SOURCE_DIRS = src
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
