TARGET = MIC-ARRAY-1V0.xn
XCC_FLAGS = -fxscope -Wall -g -O2 -report -DUSE_I2C=1
USED_MODULES = lib_device_control(>=3.2.3) lib_i2c(>=5.0.0) lib_logging(>=2.1.1) lib_mic_array_board_support(>=2.2.4)
XMOS_MAKE_PATH ?= ../..
# Ignore host dir
SOURCE_DIRS = src
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
