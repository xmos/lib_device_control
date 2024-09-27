Installing Host App
--------------------

This host application is used to communicate with the device using xscope. 
It will write commands to the device and read responses from the device.
Then, it will ensure that recieved responses are correct.

To install the host application, follow the instructions below. 
If you are using tools version 15.3 or later on Windows, ensure the `cl` compiler is set to `x64`. 
You need to activate the appropriate environment for the `cl` compiler before proceeding.

.. code-block:: console

  # The following commands apply to Windows, Linux, and macOS.
  cmake -G Ninja -B build
  ninja -C build
