# For building SPI lib_device_control host

add_library(control_spi_host INTERFACE)

# Define paths
set(HOST_SPI_INCLUDES ${CMAKE_CURRENT_LIST_DIR}/spi_driver)

# Find and link libraries
find_library(
    BCM2835_LIB
    NAMES libbcm2835.a
    PATHS ${HOST_SPI_INCLUDES}
)

target_link_libraries(control_spi_host INTERFACE ${BCM2835_LIB})

if ((${CMAKE_SYSTEM_NAME} MATCHES "Linux") AND (${CMAKE_SYSTEM_PROCESSOR} MATCHES "arm") OR (${CMAKE_SYSTEM_PROCESSOR} MATCHES "aarch64"))
    # Raspberry Pi specific I2C includes
    target_compile_options(control_spi_host INTERFACE -DCONTROL_USE_SPI=1 -DCONTROL_RPI=1)
    target_sources(control_spi_host
        INTERFACE
            ${CMAKE_CURRENT_LIST_DIR}/src/device_access_spi_rpi.c
            ${CMAKE_CURRENT_LIST_DIR}/src/control_host_util.c
    )
else()
    message(FATAL_ERROR "SPI host build not supported for OS: ${CMAKE_SYSTEM_NAME} and processor: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

target_include_directories(control_spi_host
    INTERFACE
        ${CMAKE_CURRENT_LIST_DIR}/api
        ${CMAKE_CURRENT_LIST_DIR}/inc
        ${CMAKE_CURRENT_LIST_DIR}/../lib_device_control/api
        ${CMAKE_CURRENT_LIST_DIR}/../lib_device_control/inc
        ${HOST_SPI_INCLUDES}
)

