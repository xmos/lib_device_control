# For building XSCOPE lib_device_control host

add_library(control_xscope_host INTERFACE)

# Properties and options
if (CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(control_xscope_host INTERFACE -D USE_XSCOPE=1)
else()
    target_compile_options(control_xscope_host INTERFACE -D USE_XSCOPE=1)
endif()

set(HOST_XSCOPE_INCLUDES $ENV{XMOS_TOOL_PATH}/include)

# Find and link libraries
find_library(
    XSCOPE_ENDPOINT_LIB
    NAMES xscope_endpoint.so xscope_endpoint.dylib xscope_endpoint.lib
    PATHS $ENV{XMOS_TOOL_PATH}/lib
)

target_link_libraries(control_xscope_host INTERFACE ${XSCOPE_ENDPOINT_LIB})

target_sources(control_xscope_host
    INTERFACE
        ${CMAKE_CURRENT_LIST_DIR}/src/device_access_xscope.c
        ${CMAKE_CURRENT_LIST_DIR}/src/control_host_util.c
)
target_include_directories(control_xscope_host
    INTERFACE
        ${CMAKE_CURRENT_LIST_DIR}/api
        ${CMAKE_CURRENT_LIST_DIR}/inc
        ${CMAKE_CURRENT_LIST_DIR}/../lib_device_control/api
        ${CMAKE_CURRENT_LIST_DIR}/../lib_device_control/inc
        ${HOST_XSCOPE_INCLUDES}
)

set_target_properties(control_xscope_host PROPERTIES POSITION_INDEPENDENT_CODE ON)
