cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(xscope)

# root
set(XMOS_SANDBOX_DIR ${CMAKE_SOURCE_DIR}/../../..)

# target: choose the target platform
set(APP_HW_TARGET src/XK_VOICE_L71.xn)
# set(APP_HW_TARGET src/XK-EVK-XU316-AIV.xn)

set(APP_INCLUDES src)

set(APP_COMPILER_FLAGS
  -O2
  -g
  -report
  -Wall
  -fxscope
)

set(APP_DEPENDENT_MODULES lib_device_control)
set(APP_XSCOPE_SRCS src/config.xscope)
XMOS_REGISTER_APP()
