Control library
===============

Summary
-------

Configuration and control over a number of transports

Features
........

  * Different transports such as I2C slave, USB requests, xSCOPE or GPIO
  * Multiple resources per task

Typical Resource Usage
......................

  .. resusage::
     ...

Specification
.............

*Host* controls *resources* on a *device* by sending *commands* to it over a *transport*
protocol. Resources are identified by a unique 32bit ID and exist in tasks that run on logical
cores of the device. There can be multiple resources in a task.

      "Send command c to resource R"

Some transports have a small address space such as 8bit I2C registers or 16bit USB request fields.
A *mapping* is created at runtime of resource ID to transport address. Device maintains the
mapping and host can read it if it doesn't have a copy.

Command code is 8 bits and can be a *write* command or *read* command. Bit 7 set means read
command.  Write commands can optionally include *data* bytes. Read commands always return data
bytes.

      "Send write command c to resource R with n bytes of data d"
      "Send read command c to resource R and get n bytes of data d back"

Transport protocol task (e.g. I2C slave or USB endpoint 0) has interfaces to all tasks that have
resources. Tasks with resources *register* their resources by tying them to an interface, so
when a command is received, it can be sent on the right interface.

Usage
.....

Transport task calls a function on its natural unit of data, such as I2C transaction, or USB
request, passing in the whole array of interfaces. Library's functionality happens inside the
function and once a command is complete, an interface call is made to pass the command over.

Over I2C slave, command is split into multiple I2C transactions::

      handle_i2c_write_transaction(addr, val)
      handle_i2c_write_transaction(addr, val)
      handle_i2c_write_transaction(addr, val)
      handle_i2c_write_transaction(addr, val) ==> write_command(R, c, n, d[])

Over USB requests, command is sent over a single USB request:

      handle_usb_set_request(header, data, len) ==> write_command(R, c, n, d[])

Software version and dependencies
.................................

  .. libdeps::

Related application notes
.........................

The following application notes use this library:

  * ANxxxx - [App note title 1]
  * ANxxxx - [App note title 2]
  ...
