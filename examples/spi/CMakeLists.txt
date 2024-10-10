cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(spi)

# root
set(XMOS_SANDBOX_DIR ${CMAKE_SOURCE_DIR}/../../..)

# target: choose the target platform
set(APP_HW_TARGET src/XK_VOICE_L71.xn)
# set(APP_HW_TARGET src/XK-EVK-XU316-AIV.xn)

if(APP_HW_TARGET STREQUAL "src/XK-EVK-XU316-AIV_i2c.xn")
    set(SPI_TILE_VAL 1)
else()
    set(SPI_TILE_VAL 0)
endif()

set(APP_INCLUDES src)

set(APP_COMPILER_FLAGS
  -O2
  -g
  -report
  -Wall
  -DSPI_TILE=${SPI_TILE_VAL}
)

set(APP_DEPENDENT_MODULES lib_device_control lib_spi)
XMOS_REGISTER_APP()
