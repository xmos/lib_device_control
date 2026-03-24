set(LIB_NAME lib_device_control)

set(LIB_VERSION 5.0.0)

set(LIB_DEPENDENT_MODULES "lib_xassert(4.3.2)" "lib_logging(3.4.0)")

set(LIB_INCLUDES api inc ../host/api ../host/inc)

set(LIB_COMPILER_FLAGS  -Os -Wall -g -fxscope)

set(LIB_XC_SRCS         src/control.xc
                        src/resource_table.xc
                        adapters/transport_usb.xc
                        adapters/transport_spi.xc
                        adapters/transport_i2c.xc
                        adapters/transport_xscope.xc)

set(LIB_OPTIONAL_HEADERS    control_conf.h)

XMOS_REGISTER_MODULE()
