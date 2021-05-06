#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import xmostest

def runtest():
    testlevel = 'smoke'
    resources = xmostest.request_resource('xsim')

    binary = 'usb_device/bin/usb_device.xe'.format()
    tester = xmostest.ComparisonTester(open('usb_device.expect'),
                                       'lib_device_control',
                                       'lib_device_control_tests',
                                       'usb_device',
                                       {})
    tester.set_min_testlevel(testlevel)
    xmostest.run_on_simulator(resources['xsim'], binary, simargs=[], tester=tester)
