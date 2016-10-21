#!/usr/bin/env python
import xmostest
import re
import os.path

#This can be tested locally using ./runtests.py --remote-resourcer 10.0.102.121:9995

class device_control_endtoend_tester(xmostest.Tester):
    # This checks for errors reported by all of the processes run
    # during the test. If no errors are seen the test will be marked as a pass.


    def __init__(self, transport, host_app_name, device_app_name):
        super(device_control_endtoend_tester, self).__init__()
        self.product = "lib_device_control"
        self.group = "lib_device_control_tests"
        self.test = "End-to-end-hw"
        self.config = {'transport':transport}
        self.register_test(self.product, self.group, self.test, self.config)


    def record_failure(self, failure_reason):
        # Append a newline if there isn't one already
        if not failure_reason.endswith('\n'):
            failure_reason += '\n'
        self.failures.append(failure_reason)
        print ("Failure reason: %s" % failure_reason), # Print without newline
        self.result = False


    def run(self,
            device_job_output,
            host_job_output):
        self.result = True
        self.failures = []

        # Check for any errors
        for line in (device_job_output
                     + host_job_output
                     ):
            if re.match('.*ERROR|.*error|.*Error|.*Problem|.*failed|.*could not|.*unrecognised',
                        line):
                self.record_failure(line)

        output = {'device_job_output':''.join(device_job_output),
                  'host_job_output':''.join(host_job_output)
                  }

        if not self.result:
            output['failures'] = ''.join(self.failures)
        
        xmostest.set_test_result(self.product,
                                 self.group,
                                 self.test,
                                 self.config,
                                 self.result,
                                 env={},
                                 output=output)


def runtest():

    # Check if the test is running in an environment with hardware resources
    # i.e. if not running from usb audio view it will quit. lib_device_control 
    # is in the usb audio view so it will build
    args = xmostest.getargs()
    if not args.remote_resourcer:
      # Abort the test
      print 'remote resourcer not avaliable'
      return

    device_app_name = 'usb_end_to_end_hardware/bin/usb_end_to_end_hardware.xe'.format()
    #This path is relative from xmostest in the view used. goes up and back down to lib_device_control
    host_app_name = '../../../../lib_device_control/tests/usb_end_to_end_hardware_host/bin/usb_end_to_end_hardware_host.bin'

    # Setup the tester which will determine and record the result
    tester = xmostest.CombinedTester(2, device_control_endtoend_tester("usb",
                                                       host_app_name, device_app_name))

    testlevel = 'smoke'
    tester.set_min_testlevel(testlevel)

    board = 'uac2_xcore200_mc_testrig_os_x_11'

    # Get the hardware resources to run the test on
    resources = None
    try:
        resources = xmostest.request_resource(board, tester, remote_resource_lease_time=30)
    except xmostest.XmosTestError:
        print "Unable to find required board %s required to run test" % board
        tester.shutdown()
        return

    env = ""

    # Start the xCORE DUT
    device_job = xmostest.run_on_xcore(resources['dut'], device_app_name,
                                        do_xe_prebuild = True,
                                        tester = tester[0],
                                        enable_xscope = True, 
                                        xscope_handler = None, 
                                        timeout = 30,
                                        build_env = env)

    # Start the control app
    host_job = xmostest.run_on_pc(resources['host'],
                                     [host_app_name],
                                     tester = tester[1],
                                     timeout = 30,
                                     initial_delay = 10) #Enough time for xtag to load firmware and host to enumerate device
    
    xmostest.complete_all_jobs()