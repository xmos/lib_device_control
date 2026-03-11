cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(i2c_end_to_end_sim)

# root
set(XMOS_SANDBOX_DIR ${CMAKE_SOURCE_DIR}/../../..)

# target: choose the target platform
set(APP_HW_TARGET XCORE-AI-EXPLORER)

set(APP_INCLUDES src)

set(APP_COMPILER_FLAGS
  -O2
  -g
  -report
  -Wall
  -DCONTROL_USE_I2C=1
)
set(APP_C_SRCS ../../host/src/device_access_i2c_xcore.xc ../../host/src/control_host_util.c)

set(APP_DEPENDENT_MODULES lib_device_control lib_i2c)
XMOS_REGISTER_APP()
