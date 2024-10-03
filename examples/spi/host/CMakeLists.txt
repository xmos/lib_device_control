cmake_minimum_required(VERSION 3.18)

set(CMAKE_BUILD_TYPE "Release")
project(spi_host_app)

# Define paths
set(DEVICE_CONTROL_PATH ${CMAKE_CURRENT_LIST_DIR}/../../../lib_device_control)
set(SPI_DRIVER_PATH ${DEVICE_CONTROL_PATH}/host/spi_driver)

# Define source files
set(SOURCES
    "${DEVICE_CONTROL_PATH}/host/device_access_spi_rpi.c"
    "${DEVICE_CONTROL_PATH}/host/util.c"
    "src/host.c"
)
add_executable(spi_host_app ${SOURCES})

# Directories
target_include_directories(
  spi_host_app
    PRIVATE
    src
    ${DEVICE_CONTROL_PATH}/host
    ${DEVICE_CONTROL_PATH}/api
    ${DEVICE_CONTROL_PATH}/src
    ${SPI_DRIVER_PATH}
)

# Find and link libraries
find_library(
  BCM2835_LIB
  NAMES libbcm2835.a
  PATHS ${SPI_DRIVER_PATH}
)

# Properties and options
target_compile_options(spi_host_app PRIVATE -DUSE_SPI=1 -DRPI=1 -O2)

target_link_libraries(spi_host_app PRIVATE ${BCM2835_LIB})

# Set output directory
set_target_properties(spi_host_app PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../bin)
