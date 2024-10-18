#!/usr/bin/env python
# Copyright 2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import subprocess
import logging
from pathlib import Path

def run_command(cmd, return_output=False, timeout_s=60):
    """
    Runs a command in the shell.

    Parameters:
    cmd (str or list): The command to run. Can be a string or a list of command arguments.
    return_output (bool): If True, captures and returns the output of the command.
    timeout_s (int): The timeout in seconds for the command execution.

   Returns:
    tuple: A tuple containing the return code and the standard output of the command if `return_output` is True.
           Otherwise, returns the return code and None.

    Raises:
    subprocess.TimeoutExpired: If the command times out.
    Exception: If an unexpected error occurs.
    AssertionError: If the command times out, or if an expected error occurs..

    """
    cmd = cmd if isinstance(cmd, list) else cmd.split()
    logging.debug(f"Running: {' '.join([str(i) for i in cmd])}")
    output = None
    try:
        result = subprocess.run(cmd, capture_output=return_output, text=True, timeout=timeout_s)
        output = result.stdout
        returncode = result.returncode
        logging.debug(f"Command output: {output}")
        logging.debug(f"Command return code: {returncode}")
        return (returncode, output)

    except subprocess.TimeoutExpired as e:
        logging.error(f"Error type: {type(e).__name__}")
        logging.error(f"Output: {output}")
        logging.error(f"Exception Output: {e.output}")
        logging.error(f"Exception Standard Error: {e.stderr}")
        assert False, f"Command timed out after {timeout_s} seconds"
    except Exception as e:
        logging.error(f"Error type: {type(e).__name__}")
        logging.error(f"Exception Output: {e.output}")
        logging.error(f"Exception Standard Error: {e.stderr}")
        assert False, f"An unexpected error occurred: {e}"

def build_firmware(target, project_dir=Path("."), build_dir="build", return_output=True, timeout_s=60):
    """
    Builds the XMOS firmware project using CMake and xmake.

    Parameters:
    target (str): The target to build.
    project_dir (Path or str): The path to the XMOS firmware project directory.
    build_dir (Path or str): The path to the build directory. If None, the build directory is set to the project directory.
    return_output (bool): If True, captures and returns the output of the command.
    timeout_s (int): The timeout in seconds for the command execution.

    Returns:
    Path: The path to the .xe file of the built firmware.

    Raises:
    AssertionError: If the project directory does not exist, if the build fails, or if the expected .xe file does not exist.

    """
    project_path = Path(project_dir)
    if not project_path.is_dir():
        assert False, f"The directory {project_dir} does not exist."

    build_path = Path(build_dir) if build_dir else project_path
    # Use a list below to avoid that the argument "Unix Makefiles" is split into two arguments.
    cmd = ["cmake", "-S", str(project_dir), "-G", "Unix Makefiles", "-B", str(project_dir/build_dir)]
    (returncode, _) = run_command(cmd, return_output=return_output, timeout_s=timeout_s)
    if returncode != 0:
        assert False, f"Build failed with return code {returncode}"
    cmd = f"xmake -C {project_dir / build_dir}"
    (returncode, _) = run_command(cmd, return_output=return_output, timeout_s=timeout_s)
    if returncode != 0:
        assert False, f"Build failed with return code {returncode}"
    expected_xe_file = project_dir / "bin" / f"{target}.xe"
    if not expected_xe_file.is_file():
        assert False, f"The file {expected_xe_file} does not exist."
    return expected_xe_file

def xsim_firmware(xe_file, return_output=True, timeout_s=60, sim_args=[]):
    """
    Simulates the execution of an XMOS executable file using the `xsim` tool.

    Parameters:
    xe_file (Path or str): The path to the XMOS executable (.xe) file.
    return_output (bool): If True, captures and returns the output of the command.
    timeout_s (int): The timeout in seconds for the command execution.
    sim_args (list): Additional arguments to pass to the `xsim` command.

    Returns:
    tuple: A tuple containing the return code and the standard output of the command if `return_output` is True.
           Otherwise, returns the return code and None.

    Raises:
    AssertionError: If the .xe file does not exist.
    
    """
    xe_path = Path(xe_file)
    if not xe_path.is_file():
        assert False, f"The file {xe_file} does not exist."

    cmd = [ "xsim", *sim_args, "--args", xe_path ] if sim_args else f"xsim {xe_path}"

    return run_command(cmd, return_output=return_output, timeout_s=timeout_s)
