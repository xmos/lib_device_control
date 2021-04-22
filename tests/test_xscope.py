#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import xmostest

def runtest():
    testlevel = 'smoke'
    resources = xmostest.request_resource('xsim')

    binary = 'xscope_device/bin/xscope_device.xe'.format()
    tester = xmostest.ComparisonTester(open('xscope_device.expect'),
                                       'lib_device_control',
                                       'lib_device_control_tests',
                                       'xscope_device_api',
                                       {})
    tester.set_min_testlevel(testlevel)
    xmostest.run_on_simulator(resources['xsim'], binary, simargs=[], tester=tester)
