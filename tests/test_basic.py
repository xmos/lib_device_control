#!/usr/bin/env python
import xmostest

def runtest():
    testlevel = 'smoke'
    resources = xmostest.request_resource('xsim')

    binary = 'test_basic/bin/test_basic.xe'.format()
    tester = xmostest.ComparisonTester(open('basic.expect'),
                                       'lib_device_control',
                                       'lib_device_control_tests',
                                       'basic',
                                       {})
    tester.set_min_testlevel(testlevel)
    xmostest.run_on_simulator(resources['xsim'], binary, simargs=[], tester=tester)
