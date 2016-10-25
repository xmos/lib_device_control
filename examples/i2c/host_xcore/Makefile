#Note manual build file due to xcommon not wanting to pickup hosts directory in lib_device_control

TARGET = XCORE-200-EXPLORER
XCC_FLAGS = -Wall -g -O2 -report -DUSE_I2C=1
MODULE_PATH = ../../../..

all:
	mkdir -p bin
	xcc ${XCC_FLAGS} -Isrc -I$(MODULE_PATH)/lib_i2c/lib_i2c/api/ -I$(MODULE_PATH)/lib_logging/lib_logging/api/ -I$(MODULE_PATH)/lib_device_control/lib_device_control/src/ -I$(MODULE_PATH)/lib_device_control/lib_device_control/api/ -I$(MODULE_PATH)/lib_device_control/lib_device_control/host/  -target=${TARGET} src/host.xc $(MODULE_PATH)/lib_i2c/lib_i2c/src/i2c_slave.xc $(MODULE_PATH)/lib_i2c/lib_i2c/src/i2c_master.xc $(MODULE_PATH)/lib_device_control/lib_device_control/src/control.xc $(MODULE_PATH)/lib_device_control/lib_device_control/src/resource_table.xc $(MODULE_PATH)/lib_device_control/lib_device_control/host/device_access_i2c_xcore.xc -o bin/host_xcore.xe

allconfigs: all

report_modules:
	@echo '**-modules-**'

clean:
	rm -rf bin
