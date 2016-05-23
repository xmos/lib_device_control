#!/usr/bin/env python
import xmostest

if __name__ == '__main__':
    xmostest.init()
    xmostest.register_group('lib_control',
                            'lib_control_unit_tests',
                            'lib_control unit tests',
    '''
lib_control unit tests
''')
    xmostest.runtests()
    xmostest.finish()
