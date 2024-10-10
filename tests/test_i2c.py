#!/usr/bin/env python
# Copyright 2016-2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
import utils
import subprocess
from pathlib import Path

def test_i2c_device():
    xe_path = Path(__file__).parent / 'i2c_device/bin/i2c_device.xe'
    output = None
    try:
        output = utils.xsim_firmware(xe_path)
    except Exception as e:
        assert False, f"Test failed: {type(e).__name__}"
    finally:
        print(output)

