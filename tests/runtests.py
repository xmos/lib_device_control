#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import xmostest

if __name__ == '__main__':
    xmostest.init()
    xmostest.register_group('lib_device_control',
                            'lib_device_control_tests',
                            'Control library tests',
    '''
Control library tests
''')
    xmostest.runtests()
    xmostest.finish()
