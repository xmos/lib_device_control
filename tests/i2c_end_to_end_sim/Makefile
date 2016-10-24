#Note manual build file due to xcommon not wanting to pickup hosts directory in lib_device_control

TARGET = XCORE-200-EXPLORER
XCC_FLAGS = -Wall -g -O2 -report -DUSE_I2C=1

all:
	mkdir -p bin
	xcc ${XCC_FLAGS} -Isrc -I../../../lib_i2c/lib_i2c/api/ -I../../../lib_logging/lib_logging/api/ -I../../../lib_device_control/lib_device_control/src/ -I../../../lib_device_control/lib_device_control/api/ -I../../../lib_device_control/lib_device_control/host/  -target=${TARGET} src/main.xc src/app_host.xc src/app_device.xc ../../../lib_i2c/lib_i2c/src/i2c_slave.xc ../../../lib_i2c/lib_i2c/src/i2c_master.xc ../../../lib_device_control/lib_device_control/src/control.xc ../../../lib_device_control/lib_device_control/src/resource_table.xc ../../lib_device_control/host/device_access_i2c_xcore.xc -o bin/i2c_end_to_end_sim.xe

allconfigs: all

report_modules:
	@echo '**-modules-**'

clean:
	rm -rf bin
