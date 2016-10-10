.. include:: ../../../README.rst

Device Control Library
----------------------

Introduction
............

The Device Control Library takes care of routing control messages between a host and the one or 
many controllable entities within the controlled device.


.. figure:: images/control_logical_view.pdf
   :width: 80%

   Logical view of lib_device_control

All communications are fully acknowledged and so the host will be informed whether or not the
device has successfully processed or provided the required control information.

|newpage|

Operation
.........

The *Host* controls *resources* on an xCORE *device* by sending *commands* to it over a
*transport* protocol. Resources are identified by an 8-bit identifier and exist in
tasks that run on logical cores of the device. There can be multiple resources in a task.

      **Send command c to resource r**

The command code is 8 bits and is a *write* command when bit 7 is not set or a *read* command
when bit 7 is set.

.. figure:: images/control_packet.pdf
   :width: 80%

   Packet for control communications

Read and write Commands include *data* bytes that are optional (can have a data length of zero).

      **Send write command c to resource ``r`` with ``n`` bytes of data ``d``**

      **Send read command c to resource ``r`` and get ``n`` bytes of data ``d`` back**

There is a transport task in the device (e.g. I2C slave or USB endpoint 0) that dispatches
all commands. All other tasks that have resources connect to this transport task over xC interfaces.

Tasks *register* their resources and these get bound to the tasks' xC interface. When commands are 
received by the transport task they forwarded on the matching xC interface. This means multiple tasks
residing in different cores or even tiles can be easily controlled using a single instance of 
Device Control and a single control interface to the host.

.. figure:: images/resource_mapping.pdf
   :width: 80%

   Mapping between resource IDs and xC interfaces

Commands have a result code to indicate success or failure. The result is propagated to host so
host can indicate error to the user.  

The control library supports USB, I2C and xSCOPE as physical protocols.
There are example applications for all three in the examples folder.

|newpage|

Usage
.....

The transport task receives its natural unit of data, such as I2C transaction, or USB request, and
calls a processing function on it from the library, passing in the whole array of xC interfaces.
The library's functionality happens inside the function that is called and once a command is complete, an
xC interface call is made to pass the command over.

The receiving tasks then receive a write or read command over an xC interface.

Over I2C slave, the command is split into multiple I2C transactions::

      process_i2c_write_transaction(reg, val)
      process_i2c_write_transaction(reg, val)
      process_i2c_write_transaction(reg, val)
      process_i2c_write_transaction(reg, val) ==> case i.write_command(r, c, n, d[])

Over USB requests, the command is sent over a single USB request::

      process_usb_set_request(header, data, len) ==> case i.write_command(r, c, n, d[])

It is the same for xSCOPE, the XMOS debug protocol::

      process_xscope_upload(data, len) ==> case i.write_command(r, c, n, d[])

When the system starts, the transport task does an ``init()`` call, which asks all other tasks to register
their resources::

      init() ==> i.register_resources(r[])

To ensure compatibility, a special command is provided to query the version of control xC interface.

Please see the `API`_ section for further details.

|newpage|

References
..........

I2C
***

   * https://developer.mbed.org/users/okano/notebook/i2c-access-examples
   * http://www.robot-electronics.co.uk/i2c-tutorial
   * https://www.raspberrypi.org/forums/viewtopic.php?f=44&t=15840&start=25

USB
***

   * http://www.beyondlogic.org/usbnutshell/usb6.shtml

API
---
.. doxygenenum:: control_ret

.. doxygeninterface:: control

.. doxygenfunction:: control_init

.. doxygenfunction:: control_register_resources

.. doxygenfunction:: control_process_i2c_write_start

.. doxygenfunction:: control_process_i2c_read_start

.. doxygenfunction:: control_process_i2c_write_data

.. doxygenfunction:: control_process_i2c_read_data

.. doxygenfunction:: control_process_i2c_stop

.. doxygenfunction:: control_process_usb_set_request

.. doxygenfunction:: control_process_usb_get_request

.. doxygenfunction:: control_process_xscope_upload

|newpage|

|appendix|

Known Issues
------------

There are no known issues.

.. include:: ../../../CHANGELOG.rst
