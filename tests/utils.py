#!/usr/bin/env python
# Copyright 2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import subprocess
import logging
from pathlib import Path

def run_command(cmd, check_return_code=True, return_output=True, timeout_s=60):
    """
    Runs a command in the shell.

    Parameters:
    cmd (str): The command to run.
    check_return_code (bool): If True, raises a CalledProcessError if the command exits with a non-zero status.
    return_output (bool): If True, captures and returns the output of the command.
    timeout_s (int): The timeout in seconds for the command execution.

    Returns:
    str: The standard output of the command if `return_output` is True.
    None: If `return_output` is False.

    Raises:
    subprocess.CalledProcessError: If `check_return_code` is True and the command exits with a non-zero status.
    subprocess.TimeoutExpired: If the command times out.
    Exception: If an unexpected error occurs.
    """
    cmd = cmd if isinstance(cmd, list) else cmd.split()
    logging.debug(f"Running: {' '.join([ str(i) for i in cmd])}")
    output = None
    try:
        output = subprocess.run(cmd, capture_output=True, check=check_return_code, text=True, timeout=timeout_s).stdout
        logging.debug(f"Command output: {output}")
        if return_output:
            return output
        else:
            return None
    except subprocess.CalledProcessError as e:
        logging.error(f"Error type: {type(e).__name__}")
        logging.error(f"Command failed with return code {e.returncode}")
        logging.error(f"Output: {output}")
        logging.error(f"Exception Output: {e.output}")
        logging.error(f"Exception Standard Error: {e.stderr}")

        raise
    except subprocess.TimeoutExpired as e:
        logging.error(f"Error type: {type(e).__name__}")
        logging.error(f"Command timed out after {timeout_s} seconds")
        logging.error(f"Output: {output}")
        logging.error(f"Exception Output: {e.output}")
        logging.error(f"Exception Standard Error: {e.stderr}")
        raise
    except Exception as e:
        logging.error(f"Error type: {type(e).__name__}")
        logging.error(f"An unexpected error occurred: {e}")
        logging.error(f"Output: {output}")
        raise

def build_firmware(target, project_dir=Path("."), build_dir="build", check_return_code=True, timeout_s=60):
    """
    Builds an XMOS firmware project using the `xmake` tool.

    Parameters:
    project_dir (str): The path to the XMOS firmware project directory.
    target (str): The target to build.
    build_dir (str): The path to the build directory. If None, the build directory is set to the project directory.
    check_return_code (bool): If True, raises a CalledProcessError if the command exits with a non-zero status.
    return_output (bool): If True, captures and returns the output of the command.
    timeout_s (int): The timeout in seconds for the command execution.

    Returns:
    Path to the .xe file of the built firmware.
    """

    project_path = Path(project_dir)
    if not project_path.is_dir():
        raise FileNotFoundError(f"The directory {project_dir} does not exist.")

    build_path = Path(build_dir) if build_dir else project_path
    # Use a list below to avoid that the argument "Unix Makefiles" is split into two arguments.
    cmd = [ "cmake", "-S", str(project_dir), "-G", "Unix Makefiles", "-B", str(project_dir/build_dir), "--fresh" ]
    run_command(cmd, check_return_code, return_output=False, timeout_s=timeout_s)
    cmd = f"xmake -C {project_dir / build_dir} -t {target}"
    run_command(cmd, check_return_code, return_output=False, timeout_s=timeout_s)
    expected_xe_file = project_dir / "bin" / f"{target}.xe"
    if not expected_xe_file.is_file():
        raise FileNotFoundError(f"The file {expected_xe_file} does not exist.")
    return expected_xe_file

def xsim_firmware(xe_file, check_return_code=True, return_output=True, timeout_s=60, sim_args=None):
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
    FileNotFoundError: If the .xe file does not exist.
    """

    xe_path = Path(xe_file)
    if not xe_path.is_file():
        raise FileNotFoundError(f"The file {xe_file} does not exist.")

    cmd = f"xsim {xe_path} {sim_args}" if sim_args else f"xsim {xe_path}"
    run_command(cmd, check_return_code, return_output, timeout_s)