# SOURCE_DIRS documentation:
#
#   SOURCE_DIRS = directories under the src/ directory containing source to compiler
#
# implementation:
#
#   FULL_SOURCE_DIRS := $(foreach x, $(SOURCE_DIRS), $(call EXPAND_DIR,$(call SRCDIR,$x)))
#   EXPAND_DIR = $(patsubst %/.,%,$(subst ./.,.,$(if $(filter %*,$1), $(call GET_ALL_SUBDIRS,$(subst *,.,$(patsubst %/*,%,$1))),$1)))
#
# EXPAND_DIR looks for "/." which breaks any relative paths in SOURCE_DIRS
#
# in our case:
#
#   ../../../host ---> ..../host
#
ifeq ("$(wildcard host)","")
ifneq ($(OS),WINDOWS)
$(shell ln -s ../../host)
else
$(error need a symbolic link to the host directory to build this XMOS app)
endif
endif

TARGET = XE232.xn
XCC_FLAGS = -Wall -g -D USE_I2C
USED_MODULES = lib_device_control lib_i2c lib_logging
XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
