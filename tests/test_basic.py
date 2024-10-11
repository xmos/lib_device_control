#!/usr/bin/env python
# Copyright 2016-2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
import utils
import subprocess
import logging
from pathlib import Path

def test_version():
    target = "version"
    xe_path = utils.build_firmware(target, project_dir=Path(__file__).parent / target, build_dir="build")
    output = None
    try:
        output = utils.xsim_firmware(xe_path)
    except Exception as e:
        assert False, f"Test failed: {type(e).__name__}"
    finally:
        if output:
            logging.debug(output)
def test_basic():
    target = "basic"
    xe_path = utils.build_firmware(target, project_dir=Path(__file__).parent / target, build_dir="build")
    output = None
    try:
        output = utils.xsim_firmware(xe_path)
    except Exception as e:
        assert False, f"Test failed: {type(e).__name__}"
    finally:
        if output:
            logging.debug(output)