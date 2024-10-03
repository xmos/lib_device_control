cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(spi)

# root
set(XMOS_SANDBOX_DIR ${CMAKE_SOURCE_DIR}/../../..)

# target: choose the target platform
set(APP_HW_TARGET src/XK_VOICE_L71.xn)
# set(APP_HW_TARGET src/XCORE-VISION-EXPLORER.xn)

set(APP_INCLUDES src)

set(APP_COMPILER_FLAGS
  -O3
  -g
  -report
  -Wall
  -DSPI_TILE=0
)

set(APP_DEPENDENT_MODULES lib_device_control lib_spi)
XMOS_REGISTER_APP()
