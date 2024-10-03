cmake_minimum_required(VERSION 3.18)

set(CMAKE_BUILD_TYPE "Release")
project(i2c_host_app)

# Define path to lib_device_control
set(DEVICE_CONTROL_PATH ${CMAKE_CURRENT_LIST_DIR}/../../../lib_device_control)

# Define source files
set(SOURCES
    "${DEVICE_CONTROL_PATH}/host/device_access_i2c_rpi.c"
    "${DEVICE_CONTROL_PATH}/host/util.c"
    "src/host.c"
)
add_executable(i2c_host_app ${SOURCES})

# Directories
target_include_directories(
  i2c_host_app
    PRIVATE
    src
    ${DEVICE_CONTROL_PATH}/host
    ${DEVICE_CONTROL_PATH}/api
    ${DEVICE_CONTROL_PATH}/src
)

# Properties and options
target_compile_options(i2c_host_app PRIVATE -DUSE_I2C=1 -DRPI=1 -O2)

# Set output directory
set_target_properties(i2c_host_app PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../bin)
