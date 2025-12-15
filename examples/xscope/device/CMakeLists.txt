cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(xscope)

# target: choose the target platform
set(APP_HW_TARGET src/XK_VOICE_L71.xn)
# set(APP_HW_TARGET src/XK-EVK-XU316-AIV.xn)

set(APP_INCLUDES src ../shared)

# To enable XSCOPE transport in the library, this application must build 'xscope' configuration
set(TRANSPORT_CONFIG  "XSCOPE")

set(APP_COMPILER_FLAGS
  -O2
  -g
  -report
  -Wall
  -fxscope
  -DDEBUG_PRINT_ENABLE_TRANSPORT=1
)

set(APP_DEPENDENT_MODULES lib_device_control)

set(APP_XSCOPE_SRCS src/config.xscope)

set(XMOS_SANDBOX_DIR        ${CMAKE_CURRENT_LIST_DIR}/../../../..)

XMOS_REGISTER_APP()
