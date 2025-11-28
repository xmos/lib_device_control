cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)

project(lib_device_control_examples)

add_subdirectory(i2c)
add_subdirectory(spi)
add_subdirectory(usb)
add_subdirectory(xscope)
