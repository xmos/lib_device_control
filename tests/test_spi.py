#!/usr/bin/env python
# Copyright 2016-2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
import utils
import logging
from pathlib import Path

def test_spi_device():
    """
    This test runs on the device using xsim.
    It creates several SPI control interfaces, it sends some read and write commands, and it checks that the responses are correct.
    """
    target = "spi_device"
    xe_path = utils.build_firmware(target, project_dir=Path(__file__).parent / target)
    proc = utils.xsim_firmware(xe_path)
    if proc.stdout:
        logging.debug(proc.stdout)
    assert proc.returncode == 0, f"Test failed: {proc.returncode}"
