#!/usr/bin/env python
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
