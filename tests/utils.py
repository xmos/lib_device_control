#!/usr/bin/env python
# Copyright 2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import subprocess

def xsim_firmware(xe_file, check_return_code=True, return_output=True, timeout_s=60):
    """
    Simulates the execution of an XMOS executable file using the `xsim` tool.

    Parameters:
    xe_file (str): The path to the XMOS executable (.xe) file.
    check_return_code (bool): If True, raises a CalledProcessError if the command exits with a non-zero status.
    return_output (bool): If True, captures and returns the output of the command.
    timeout_s (int): The timeout in seconds for the command execution.

    Returns:
    str: The standard output of the command if `return_output` is True.
    None: If `return_output` is False.

    Raises:
    subprocess.CalledProcessError: If `check_return_code` is True and the command exits with a non-zero status.
    subprocess.TimeoutExpired: If the command times out.

    Example:
    >>> output = xsim_firmware("path/to/firmware.xe")
    >>> print(output)
    """
    cmd = f"xsim {xe_file}"
    print(f"Running: {cmd}")
    output = None
    try:
        if return_output:
            return subprocess.run(cmd.split(), capture_output=True, check=check_return_code, text=True, timeout=timeout_s).stdout
        else:
            subprocess.run(cmd.split(), check=check_return_code, timeout=timeout_s)
    except subprocess.CalledProcessError as e:
        print(f"Error type: {type(e).__name__}")
        print(f"Command failed with return code {e.returncode}")
        print(f"Output: {e.output}")
        raise
    except subprocess.TimeoutExpired as e:
        print(f"Error type: {type(e).__name__}")
        print(f"Command timed out after {timeout_s} seconds")
        raise
    except Exception as e:
        print(f"Error type: {type(e).__name__}")
        print(f"An unexpected error occurred: {e}")
        raise