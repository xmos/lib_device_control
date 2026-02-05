cmake_minimum_required(VERSION 3.21)

set(CMAKE_BUILD_TYPE "Release")
project(usb_host_app)

include("${CMAKE_CURRENT_LIST_DIR}/../../../host/host_build_usb.cmake")

add_executable(usb_host_app "src/host.c")

target_link_libraries(usb_host_app PRIVATE control_usb_host)

# Set output directory
set_target_properties(
    usb_host_app PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/../bin"
)

# Directories
target_include_directories(
    usb_host_app PRIVATE
        src
        ../shared
)

# Properties and options
if (CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(usb_host_app PRIVATE /W4 /WX /O2 /EHsc)
else()
    target_compile_options(usb_host_app PRIVATE -Wall -Wextra -Werror -O2)
endif()

