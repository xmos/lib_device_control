# For building USB lib_device_control host

add_library(control_usb_host INTERFACE)

# Properties and options
if (CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(control_usb_host INTERFACE -D USE_USB=1)
else()
    target_compile_options(control_usb_host INTERFACE -D USE_USB=1)
endif()

# Discern OS for libusb library location
if ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") AND (${CMAKE_SYSTEM_PROCESSOR} MATCHES "x86_64"))
    target_link_directories(control_usb_host INTERFACE "${CMAKE_CURRENT_LIST_DIR}/libusb/OSX64")
    set(HOST_USB_INCLUDES "${CMAKE_CURRENT_LIST_DIR}/libusb/OSX64")
    target_link_libraries(control_usb_host INTERFACE usb-1.0.0)

elseif ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") AND (${CMAKE_SYSTEM_PROCESSOR} MATCHES "arm64"))
    target_link_directories(control_usb_host INTERFACE "${CMAKE_CURRENT_LIST_DIR}/libusb/OSXARM")
    set(HOST_USB_INCLUDES "${CMAKE_CURRENT_LIST_DIR}/libusb/OSXARM")
    target_link_libraries(control_usb_host INTERFACE usb-1.0.0)

elseif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    find_package(PkgConfig)
    pkg_check_modules(libusb-1.0 REQUIRED libusb-1.0)
    set(HOST_USB_INCLUDES ${libusb-1.0_INCLUDE_DIRS})
    target_link_libraries(control_usb_host INTERFACE usb-1.0)

elseif (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    target_link_directories(control_usb_host INTERFACE "${CMAKE_CURRENT_LIST_DIR}/libusb/Win64")
    set(HOST_USB_INCLUDES "${CMAKE_CURRENT_LIST_DIR}/libusb/Win64")
    target_link_libraries(control_usb_host INTERFACE libusb-1.0)
endif()

target_sources(control_usb_host
    INTERFACE
        ${CMAKE_CURRENT_LIST_DIR}/src/device_access_usb.c
        ${CMAKE_CURRENT_LIST_DIR}/src/control_host_util.c
)
target_include_directories(control_usb_host
    INTERFACE
        ${CMAKE_CURRENT_LIST_DIR}/api
        ${CMAKE_CURRENT_LIST_DIR}/inc
        ${CMAKE_CURRENT_LIST_DIR}/../lib_device_control/api
        ${CMAKE_CURRENT_LIST_DIR}/../lib_device_control/inc
        ${HOST_USB_INCLUDES}
)

set_target_properties(control_usb_host PROPERTIES POSITION_INDEPENDENT_CODE ON)
