cmake_minimum_required(VERSION 3.18)

set(CMAKE_BUILD_TYPE "Release")
project(i2c_host_app)

include("${CMAKE_CURRENT_LIST_DIR}/../../../host/host_build_i2c.cmake")

add_executable(i2c_host_app "src/host.c")

target_link_libraries(i2c_host_app PRIVATE control_i2c_host)

# Directories
target_include_directories(
    i2c_host_app PRIVATE
        src
        ../shared
)

# Properties and options
target_compile_options(i2c_host_app PRIVATE -Wall -Wextra -Werror -O2)

# Set output directory
set_target_properties(i2c_host_app PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../bin)
