cmake_minimum_required(VERSION 3.21)

# Compile for x86_64 on Mac as we can't support the M1 ARM architecture yet
set(CMAKE_OSX_ARCHITECTURES
    "x86_64"
    CACHE INTERNAL "")

set(CMAKE_BUILD_TYPE "Release")
project(usb_host_app)

# Define path to lib_device_control
set(DEVICE_CONTROL_PATH ${CMAKE_CURRENT_LIST_DIR}/../../../lib_device_control)

# Define source files
set(SOURCES
    "${DEVICE_CONTROL_PATH}/host/device_access_usb.c"
    "${DEVICE_CONTROL_PATH}/host/util.c"
    "src/host.c"
)
add_executable(usb_host_app ${SOURCES})

# Discern OS for libusb library location
if ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") AND (${CMAKE_SYSTEM_PROCESSOR} MATCHES "x86_64"))
    target_link_directories(usb_host_app PRIVATE "${DEVICE_CONTROL_PATH}/host/libusb/OSX64")
    set(libusb-1.0_INCLUDE_DIRS "${DEVICE_CONTROL_PATH}/host/libusb/OSX64")
    set(LINK_LIBS usb-1.0.0)
elseif ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") AND (${CMAKE_SYSTEM_PROCESSOR} MATCHES "arm64"))
    target_link_directories(usb_host_app PRIVATE "${DEVICE_CONTROL_PATH}/host/libusb/OSXARM")
    set(libusb-1.0_INCLUDE_DIRS "${DEVICE_CONTROL_PATH}/host/libusb/OSXARM")
    set(LINK_LIBS usb-1.0.0)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    find_package(PkgConfig)
    pkg_check_modules(libusb-1.0 REQUIRED libusb-1.0)
    set(LINK_LIBS usb-1.0)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    add_compile_definitions(nologo WAll WX- O2 EHa)
    target_link_directories(usb_host_app PRIVATE "${DEVICE_CONTROL_PATH}/host/libusb/Win32")
    set(libusb-1.0_INCLUDE_DIRS "${DEVICE_CONTROL_PATH}/host/libusb/Win32")
    set(LINK_LIBS libusb)
endif()

# Directories
target_include_directories(
  usb_host_app
    PRIVATE
    src
    ${DEVICE_CONTROL_PATH}/host
    ${DEVICE_CONTROL_PATH}/api
    ${DEVICE_CONTROL_PATH}/src
    $ENV{XMOS_TOOL_PATH}/include
    ${libusb-1.0_INCLUDE_DIRS}
)

# Properties and options
target_compile_options(usb_host_app PRIVATE -D USE_USB -O2)

target_link_libraries(usb_host_app PRIVATE ${LINK_LIBS})

# Set output directory
set_target_properties(usb_host_app PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../bin)
