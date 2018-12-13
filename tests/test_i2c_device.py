#!/usr/bin/env python
# Copyright (c) 2016-2018, XMOS Ltd, All rights reserved
import xmostest

def runtest():
    testlevel = 'smoke'
    resources = xmostest.request_resource('xsim')

    binary = 'i2c_device/bin/i2c_device.xe'.format()
    tester = xmostest.ComparisonTester(open('i2c_device.expect'),
                                       'lib_device_control',
                                       'lib_device_control_tests',
                                       'i2c_device',
                                       {})
    tester.set_min_testlevel(testlevel)
    xmostest.run_on_simulator(resources['xsim'], binary, simargs=[], tester=tester)
