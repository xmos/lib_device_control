# Building host lib_device_control applications

add_library(control_i2c_host INTERFACE)

if ((${CMAKE_SYSTEM_NAME} MATCHES "Linux") AND (${CMAKE_SYSTEM_PROCESSOR} MATCHES "arm"))
    # Raspberry Pi specific I2C includes
    target_compile_options(control_i2c_host INTERFACE -DUSE_I2C=1 -DRPI=1)
    target_sources(control_i2c_host
        INTERFACE
            ${CMAKE_CURRENT_LIST_DIR}/src/device_access_i2c_rpi.c
            ${CMAKE_CURRENT_LIST_DIR}/src/control_host_util.c
    )
elseif (${CMAKE_SYSTEM_PROCESSOR} MATCHES "XCORE_XS")
    # XCore specific I2C includes
    target_compile_options(control_i2c_host INTERFACE -DUSE_I2C=1)
    target_sources(control_i2c_host
        INTERFACE
            ${CMAKE_CURRENT_LIST_DIR}/src/device_access_i2c_xcore.xc
            ${CMAKE_CURRENT_LIST_DIR}/src/control_host_util.c
    )
else()
    message(FATAL_ERROR "I2C host build not supported for OS: ${CMAKE_SYSTEM_NAME} and processor: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

target_include_directories(control_i2c_host
    INTERFACE
        ${CMAKE_CURRENT_LIST_DIR}/api
        ${CMAKE_CURRENT_LIST_DIR}/inc
        ${CMAKE_CURRENT_LIST_DIR}/../lib_device_control/api
        ${CMAKE_CURRENT_LIST_DIR}/../lib_device_control/inc
)
