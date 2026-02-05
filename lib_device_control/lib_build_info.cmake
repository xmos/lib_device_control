set(LIB_NAME lib_device_control)

set(LIB_VERSION 5.0.0)

set(LIB_DEPENDENT_MODULES "lib_xassert(4.3.2)" "lib_logging(3.4.0)")

set(LIB_INCLUDES api inc ../host/api ../host/inc)

set(LIB_COMPILER_FLAGS -Os -Wall -g -fxscope)

set(LIB_XC_SRCS src/control.xc src/resource_table.xc)

# Add transport source files based on configuration
string( TOUPPER "${TRANSPORT_CONFIG}" TRANSPORT_UPPER )

if (TRANSPORT_UPPER STREQUAL "USB")
    list(APPEND LIB_XC_SRCS adapters/transport_usb.xc)

elseif (TRANSPORT_UPPER STREQUAL "I2C")
    list(APPEND LIB_XC_SRCS adapters/transport_i2c.xc)

elseif (TRANSPORT_UPPER STREQUAL "SPI")
    list(APPEND LIB_XC_SRCS adapters/transport_spi.xc)

elseif (TRANSPORT_UPPER STREQUAL "XSCOPE")
    list(APPEND LIB_XC_SRCS adapters/transport_xscope.xc)
endif()

XMOS_REGISTER_MODULE()
