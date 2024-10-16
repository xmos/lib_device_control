#!/usr/bin/env python
# Copyright 2016-2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
import utils
import subprocess
import logging
from pathlib import Path

def test_version():
    """
    This test runs on the device using xsim, and it checks if the control version can be read over I2C, SPI, USB and XSCOPE.
    """
    target = "version"
    xe_path = utils.build_firmware(target, project_dir=Path(__file__).parent / target)
    output = None
    try:
        output = utils.xsim_firmware(xe_path)
    except Exception as e:
        assert False, f"Test failed: {type(e).__name__}"
    finally:
        if output:
            logging.debug(output)
def test_basic():
    """
    This test runs on the device only using xsim, and it checks if control_init() is successful.
    """
    target = "basic"
    xe_path = utils.build_firmware(target, project_dir=Path(__file__).parent / target)
    output = None
    try:
        output = utils.xsim_firmware(xe_path)
    except Exception as e:
        assert False, f"Test failed: {type(e).__name__}"
    finally:
        if output:
            logging.debug(output)
