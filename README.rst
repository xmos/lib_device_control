Device control library
======================

Summary
-------

Configuration and control over a number of transports

Features
........

  * Different transports such as I2C slave, USB requests or xSCOPE
  * Multiple resources per task

Typical resource usage
......................

Only a small amount of code space is needed. Everything is in the form of function calls,
so no additional logical cores are consumed. I/O requirements depend on which transport
is used.

Specification
.............

*Host* controls *resources* on an xCORE *device* by sending *commands* to it over a
*transport* protocol. Resources are identified by an 8bit identifier and exist in
tasks that run on logical cores of the device. There can be multiple resources in a task.

      **Send command c to resource r**

Command code is 8 bits and can be a *write* command when bit 7 is not set or a *read* command
when bit 7 is set. Commands include *data* bytes that are optional, both write and read
commands.

      **Send write command c to resource r with n bytes of data d**

      **Send read command c to resource r and get n bytes of data d back**

There is a transport task in the device (e.g. I2C slave or USB endpoint 0) that dispatches
all commands. All other tasks that have resources connect to this transport task over xC
interfaces.

Tasks *register* their resources and these get tied to the tasks' interface. Commands are
then received in transport task and forwarded on the right interface.

Commands have a result code to indicate success or failure. Result is propagated to host so
host can indicate error to the user.  

Usage
.....

Transport task receives its natural unit of data, such as I2C transaction, or USB request, and
calls a processing function on it from the library, passing in the whole array of interfaces.
Library's functionality happens inside the function and once a command is complete, an
interface call is made to pass the command over.

Other tasks then receive a write or read command over an xC interface.

Over I2C slave, command is split into multiple I2C transactions::

      process_i2c_write_transaction(reg, val)
      process_i2c_write_transaction(reg, val)
      process_i2c_write_transaction(reg, val)
      process_i2c_write_transaction(reg, val) ==> case i.write_command(r, c, n, d[])

Over USB requests, command is sent over a single USB request::

      process_usb_set_request(header, data, len) ==> case i.write_command(r, c, n, d[])

Same for xSCOPE, the XMOS debug protocol::

      process_xscope_upload(data, len) ==> case i.write_command(r, c, n, d[])

When system starts, transport task does an init call, which asks all other tasks to register
their resources::

      init() ==> i.register_resources(r[])

For compatibility, a special command is provided to query version of control interface.

Software version and dependencies
.................................

  .. libdeps::

Related application notes
.........................

The following application notes use this library:

  * ANxxxx - [App note title 1]
  * ANxxxx - [App note title 2]
  ...
