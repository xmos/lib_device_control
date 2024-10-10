cmake_minimum_required(VERSION 3.21)

# Check if XMOS_TOOL_PATH is defined
if(NOT DEFINED ENV{XMOS_TOOL_PATH})
    message(FATAL_ERROR "XMOS_TOOL_PATH must be defined.")
endif()

# Compile for x86_64 on Mac as we can't support the M1 ARM architecture yet
set(CMAKE_OSX_ARCHITECTURES
    "x86_64"
    CACHE INTERNAL "")

set(CMAKE_BUILD_TYPE "Release")
project(xscope_host_app)

# Define path to lib_device_control
set(DEVICE_CONTROL_PATH ${CMAKE_CURRENT_LIST_DIR}/../../../lib_device_control)

# Define source files
set(SOURCES
    "${DEVICE_CONTROL_PATH}/host/device_access_xscope.c"
    "${DEVICE_CONTROL_PATH}/host/util.c"
    "src/host.c"
)
add_executable(xscope_host_app ${SOURCES})

# Directories
target_include_directories(
  xscope_host_app
    PRIVATE
    src
    ${DEVICE_CONTROL_PATH}/host
    ${DEVICE_CONTROL_PATH}/api
    ${DEVICE_CONTROL_PATH}/src
    $ENV{XMOS_TOOL_PATH}/include
)

# Properties and options
target_compile_options(xscope_host_app PRIVATE -D USE_XSCOPE -O2)

# Find and link libraries
find_library(
  XSCOPE_ENDPOINT_LIB
  NAMES xscope_endpoint.so xscope_endpoint.dylib xscope_endpoint.lib
  PATHS $ENV{XMOS_TOOL_PATH}/lib)

target_link_libraries(xscope_host_app PRIVATE ${XSCOPE_ENDPOINT_LIB})

# Set output directory
set_target_properties(xscope_host_app PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../bin)
