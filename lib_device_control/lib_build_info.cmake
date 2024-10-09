set(LIB_NAME lib_device_control)
set(LIB_VERSION 5.0.0)
set(LIB_DEPENDENT_MODULES "lib_xassert(4.0.0)" "lib_logging(3.0.0)")
set(LIB_INCLUDES api src host)
set(LIB_COMPILER_FLAGS -Os -Wall -g -fxscope)

XMOS_REGISTER_MODULE()
