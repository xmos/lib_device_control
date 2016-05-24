#!/usr/bin/env python
import xmostest

if __name__ == '__main__':
    xmostest.init()
    xmostest.register_group('lib_device_control',
                            'lib_device_control_unit_tests',
                            'lib_device_control unit tests',
    '''
lib_device_control unit tests
''')
    xmostest.runtests()
    xmostest.finish()
