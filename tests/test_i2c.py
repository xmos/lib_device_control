#!/usr/bin/env python
# Copyright 2016-2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
import utils
import subprocess
import logging
from pathlib import Path

def test_i2c_device():
    """
    This test runs on the device using xsim.
    It creates several I2C control interfaces, it sends some read and write commands, and it checks that the responses are correct.
    """
    target = "i2c_device"
    xe_path = utils.build_firmware(target, project_dir=Path(__file__).parent / target, build_dir="build")
    (returncode, output) = utils.xsim_firmware(xe_path)
    if output:
        logging.debug(output)
    assert returncode == 0, f"Test failed: {returncode}"

def test_i2c_end_to_end_sim():
    """
    This test runs on the device using xsim with the LoopbackPort plugins.
    It creates an I2C master server and a host control app on one tile, and an I2C slave client and a device control app on the other tile.
    The master and slave sides are connected via two ports, one for SCL pin and one for SDA pin.
    The host app on the master side sends some read and write commands to the device app on the slave side, and it checks that the operations return CONTROL_SUCCESS.
    """
    target = "i2c_end_to_end_sim"
    xe_path = utils.build_firmware(target, project_dir=Path(__file__).parent / target, build_dir="build")
    output = None
    # Do not split the plugin arguments into separate strings to avoid errors when using subprocess.run
    sim_args = [ "--plugin", "LoopbackPort.dll", "-pullup -port tile[0] XS1_PORT_1A 1 0 -port tile[1] XS1_PORT_1A 1 0", "--plugin", "LoopbackPort.dll", "-pullup -port tile[0] XS1_PORT_1B 1 0 -port tile[1] XS1_PORT_1B 1 0",
                 "--trace-to", "/dev/null" ] #This extra argument has been added to redirect the warnings about pin driving from stdout

    (returncode, output) = utils.xsim_firmware(xe_path, sim_args=sim_args)

    if output:
        logging.debug(output)
    assert returncode == 0, f"Test failed: {returncode}"
