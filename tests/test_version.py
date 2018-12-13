#!/usr/bin/env python
# Copyright (c) 2016-2018, XMOS Ltd, All rights reserved
import xmostest

def runtest():
    testlevel = 'smoke'
    resources = xmostest.request_resource('xsim')

    binary = 'version/bin/version.xe'.format()
    tester = xmostest.ComparisonTester(open('version.expect'),
                                       'lib_device_control',
                                       'lib_device_control_tests',
                                       'version',
                                       {})
    tester.set_min_testlevel(testlevel)
    xmostest.run_on_simulator(resources['xsim'], binary, simargs=[], tester=tester)
