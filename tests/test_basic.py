#!/usr/bin/env python
# Copyright 2016-2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
import utils
import logging
from pathlib import Path

@pytest.mark.parametrize("target", ["init", "version"])
def test_basic(target):
    """
    This test runs on the device using xsim, and it checks if control_init() is successful and the control version can be read over I2C, SPI, USB and XSCOPE.
    """
    xe_path = utils.build_firmware(target, project_dir=Path(__file__).parent / target)
    proc = utils.xsim_firmware(xe_path)
    if proc.stdout:
        logging.debug(proc.stdout)
    assert proc.returncode == 0, f"Test failed: {proc.returncode}"
