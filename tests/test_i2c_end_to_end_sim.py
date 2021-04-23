#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import xmostest

def runtest():
    testlevel = 'smoke'
    resources = xmostest.request_resource('xsim')

    binary = 'i2c_end_to_end_sim/bin/i2c_end_to_end_sim.xe'.format()
    tester = xmostest.ComparisonTester(open('i2c_end_to_end_sim.expect'),
                                       'lib_device_control',
                                       'lib_device_control_tests',
                                       'i2c_end_to_end',
                                       {})
    tester.set_min_testlevel(testlevel)
    simargs =  ("--plugin", "LoopbackPort.dll", "-pullup -port tile[0] XS1_PORT_1A 1 0 -port tile[1] XS1_PORT_1A 1 0 ",
                    "--plugin", "LoopbackPort.dll", "-pullup -port tile[0] XS1_PORT_1B 1 0 -port tile[1] XS1_PORT_1B 1 0 ",
                    "--trace-to", "/dev/null") #This extra argument has been added to redirect the warnings about pin driving from stdout
    xmostest.run_on_simulator(resources['xsim'], binary, simargs=simargs, tester=tester)