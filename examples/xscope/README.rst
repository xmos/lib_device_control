Example: Xscope
===============

The Device Control library provides an API and a set of communication layers that
provide a host to device control path which is agnostic of the actual transport used.

Multiple transport layers are provided as part of the library including I2C, xSCOPE and USB.
This example demonstrates the use of the xSCOPE transport layer.
The host application sends commands to the device application which processes the commands and sends a response back to the host.
There are simple checks to verify the correctness of the commands and the responses.

Build host application
----------------------

This host application is used to communicate with the device using xscope.
It will write commands to the device and read responses from the device.
Then, it will ensure that received responses are correct.

To install the host application, follow the instructions below.
If you are using tools version 15.3 or later on Windows, ensure the `cl` compiler is set to `x64`.
You need to activate the appropriate environment for the `cl` compiler before proceeding.

.. code-block:: console

  # The following commands apply to Windows, Linux, and macOS.
  cmake -G Ninja -B build
  ninja -C build


Build firmware application
--------------------------

Run the following command from the example folder:

.. code-block:: console

  cmake -G "Unix Makefiles" -B build
  xmake -C build

Running example
---------------

.. code-block:: console

    # Device: run the xscope device application
    xrun --xscope-port localhost:10101 bin/xscope.xe
    # Host: run the xscope host application
    # (Windows)
    call "bin/xscope_host_app.exe"
    # (Linux, MacOS)
    ./bin/xscope_host_app

Output
------

If the run is successful, the host application will display "Done", otherwise it will display an error.
Errors indicate that the device application did not respond correctly to the commands sent by the host application.
