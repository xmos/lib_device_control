cmake_minimum_required(VERSION 3.21)

# Check if XMOS_TOOL_PATH is defined
if(NOT DEFINED ENV{XMOS_TOOL_PATH})
    message(FATAL_ERROR "XMOS_TOOL_PATH must be defined.")
endif()

# Compile for x86_64 on Mac as we can't support the M1 ARM architecture yet
set(CMAKE_OSX_ARCHITECTURES
    "x86_64"
    CACHE INTERNAL ""
)

set(CMAKE_BUILD_TYPE "Release")
project(xscope_host_app)

include("${CMAKE_CURRENT_LIST_DIR}/../../../host/host_build_xscope.cmake")

add_executable(xscope_host_app "src/host.c")

target_link_libraries(xscope_host_app PRIVATE control_xscope_host)

# Set output directory
set_target_properties(
    xscope_host_app PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/../bin"
)

# Directories
target_include_directories(
    xscope_host_app PRIVATE
        src
        ../shared
)

# Properties and options
if (CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(xscope_host_app PRIVATE /W4 /WX /O2 /EHsc)
else()
    target_compile_options(xscope_host_app PRIVATE -Wall -Wextra -Werror -O2)
endif()
