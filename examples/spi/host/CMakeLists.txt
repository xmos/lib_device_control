cmake_minimum_required(VERSION 3.18)

set(CMAKE_BUILD_TYPE "Release")
project(spi_host_app)

include("${CMAKE_CURRENT_LIST_DIR}/../../../host/host_build_spi.cmake")

add_executable(spi_host_app "src/host.c")

target_link_libraries(spi_host_app PRIVATE control_spi_host)

# Directories
target_include_directories(
    spi_host_app PRIVATE
        src
        ../shared
)

# Properties and options
target_compile_options(spi_host_app PRIVATE -Wall -Wextra -Werror -O2)

# Set output directory
set_target_properties(spi_host_app PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../bin)
