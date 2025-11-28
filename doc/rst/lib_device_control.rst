############################################
lib_device_control: Device Control for XCORE
############################################

************
Introduction
************

The Device Control Library handles the routing of control messages between a host and one or
many controllable resources within the controlled device.


.. figure:: ../images/control_logical_view.pdf
   :width: 80%

   Logical view of lib_device_control

All communications are fully acknowledged and so the host will be informed whether or not the
device has correctly received or provided the required control information.

*********
Operation
*********

The `Host` controls resources on an XCORE device by sending `commands` to it over a
`transport` protocol. Resources are identified by an 8-bit identifier and exist in
tasks that run on logical cores of the device. There can be multiple resources in a task.

.. code-block:: console

   Send command c to resource r

The command code is 8 bits and is a `write` command when bit 7 is not set or a `read` command
when bit 7 is set.

.. figure:: ../images/control_packet.pdf
   :width: 80%

   Packet for control communications

Read and write Commands include `data` bytes that are optional (can have a data length of zero).

.. code-block:: console

   Send write command c to resource ``r`` with ``n`` bytes of data ``d``

   Send read command c to resource ``r`` and get ``n`` bytes of data ``d`` back

There is a transport task in the device (e.g. I2C slave or USB endpoint 0) that dispatches
all commands. All other tasks that have resources connect to this transport task over xC interfaces.

Tasks `register` their resources and these get bound to the tasks' xC interface. When commands are
received by the transport task they forwarded over the matching xC interface.


.. figure:: ../images/resource_mapping.pdf
   :width: 80%

   Mapping between resource IDs and xC interfaces


This means multiple tasks residing in different cores or even tiles on the device can be easily
controlled using a single instance of the Device Control library and a single control interface to the host.

Commands have a result code to indicate success or failure. The result is propagated to host so
host can indicate error to the user.

The control library supports USB (device is USB device), I2C (device is I2C slave) and xSCOPE
(device is target connected via xTAG debug adapter) as physical protocols. The maximum data packet size for
each of the transport types is as follows:

.. list-table:: Maximum Data Length for Device Control Library Transports
 :header-rows: 1

 * - Transport
   - Data length
   - Limitation
 * - I2C
   - 253 Bytes
   - Arbitrary
 * - USB
   - 64 Bytes
   - USB control transfer specification
 * - xSCOPE
   - 256 Bytes
   - Arbitrary

It would be straightforward to add support for additional physical protocols such as UART, SPI or
TCP/UDP over Ethernet or add additional control hosts where the hardware and operating system supports it.


*****
Usage
*****

``lib_device_control`` is intended to be used with the
`XCommon CMake <https://www.xmos.com/file/xcommon-cmake-documentation/?version=latest>`_,
the `XMOS` application build and dependency management system.

To use this library in an application include ``lib_device_control`` in the application's ``APP_DEPENDENT_MODULES`` list in
`CMakeLists.txt`, for example:

.. code-block:: cmake

    set(APP_DEPENDENT_MODULES "lib_device_control")

.. note:: Dependent modules should be pinned to release versions where possible, otherwise the
   latest commit on the `develop` branch will be used.  For further details on managing modules,
   pinning to a release version and other options, please see the page
   `xcommon-cmake Dependency Management <https://www.xmos.com/documentation/XM-015090-PC/html/doc/dependency_management.html>`_.

All ``lib_device_control`` functions can be accessed via the ``device_control.h`` header file, for example:

.. code-block:: C

    #include "device_control.h"

*********
Transport
*********

The transport task receives its natural unit of data, such as I2C transaction, or USB request, and
calls a processing function on it from the library. At the same time it passes in the whole array of xC interfaces
which connect to all of the controlled tasks.

The library's logic happens inside the function that is called and once a command is complete, an
xC interface call is made to pass the command over to the controlled resource.

The receiving task then receives a write or read command over the xC interface.

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

To ensure compatibility, a special command is provided to query the version of control xC interface. This
allows the host to query the device and check that it is running the same version, which will ensure
command compatibility.

Please see the `Device side`_ and `Host side`_ sections for further details.

**********
References
**********

I2C
===

* https://developer.mbed.org/users/okano/notebook/i2c-access-examples
* http://www.robot-electronics.co.uk/i2c-tutorial
* https://www.raspberrypi.org/forums/viewtopic.php?f=44&t=15840&start=25

USB
===

* http://www.beyondlogic.org/usbnutshell/usb6.shtml

***
API
***

Shared
======

.. doxygengroup:: control_shared_group

.. doxygengroup:: control_transport_shared_group

Device side
===========

.. doxygendefine:: MAX_RESOURCES_PER_INTERFACE

.. doxygengroup:: control

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

Host side
=========

.. doxygenfunction:: control_init_xscope

.. doxygenfunction:: control_cleanup_xscope

.. doxygenfunction:: control_init_i2c

.. doxygenfunction:: control_cleanup_i2c

.. doxygenfunction:: control_init_usb

.. doxygenfunction:: control_query_version

.. doxygenfunction:: control_write_command

.. doxygenfunction:: control_read_command
