#!/usr/bin/env python
import xmostest

if __name__ == '__main__':
    xmostest.init()
    xmostest.register_group('lib_device_control',
                            'lib_device_control_unit_tests',
                            'Unit tests',
    '''
Unit tests
''')
    xmostest.register_group('lib_device_control',
                            'lib_device_control_transport_tests',
                            'Transport tests',
    '''
Transport tests
''')
    xmostest.runtests()
    xmostest.finish()
