cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(i2c)

# root
set(XMOS_SANDBOX_DIR ${CMAKE_SOURCE_DIR}/../../..)

# target: choose the target platform
set(APP_HW_TARGET src/XK_VOICE_L71.xn)
# set(APP_HW_TARGET src/XCORE-VISION-EXPLORER.xn)

set(APP_INCLUDES src)

set(APP_COMPILER_FLAGS
  -O2
  -g
  -report
  -Wall
)

set(APP_DEPENDENT_MODULES lib_device_control lib_i2c)
XMOS_REGISTER_APP()
