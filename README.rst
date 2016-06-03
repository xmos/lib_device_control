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

  .. resusage::
     ...

Specification
.............

*Host* controls *resources* on a *device* by sending *commands* to it over a *transport*
protocol. Resources are identified by a unique 32bit ID and exist in tasks that run on logical
cores of the device. There can be multiple resources in a task.

      **Send command c to resource R**

Some transports have a small address space such as 8bit I2C registers or 16bit USB request fields.
A *mapping* is created at runtime of resource ID to *index*, a smaller address sent over transport.
Device maintains the mapping of resource ID to indices and host can read it if it doesn't know it.

Command code is 8 bits and can be a *write* command or *read* command. Bit 7 set means read
command. Write commands can optionally include *data* bytes. Read commands always return data
bytes.

      **Send write command c to resource R with n bytes of data d**

      **Send read command c to resource R and get n bytes of data d back**

There is a transport task in the device (e.g. I2C slave or USB endpoint 0) and all other tasks
that have resources connect to it over an xC interface.

Tasks *register* their resources by tying them to an interface, so when a command is received,
it can be sent on the right interface.

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
      process_i2c_write_transaction(reg, val) ==> case i.write_command(R, c, n, d[])

Over USB requests, command is sent over a single USB request::

      process_usb_ep0_set_request(header, data, len) ==> case i.write_command(R, c, n, d[])

Same for xSCOPE, the XMOS debug protocol::

      process_xscope_upload(data, len) ==> case i.write_command(R, c, n, d[])

When system starts, transport task does an init call, which asks all other tasks to register
their resources::

      init() ==> i.register_resources(R[])

This is when mapping of resource ID to indices is built. It's just an increasing sequence::

      i1.register_resources "i1r1" "i1r2"        --> 1 2
      i2.register_resources "i2r1"               --> 3
      i3.register_resources "i3r1" "i3r2" "i3r3" --> 4 5 6

Host
....

Hosts builds a transport unit of data, e.g. I2C transaction, and sends it. It can use own
code or there is a cross platform C template provided as well::

      control_xscope_create_upload_buffer(buffer, c, R, n, d[])

      control_usb_ep0_fill_header(header, c, I(R), n)

where ``I(R)`` is index corresponding to resource ID R. Host can have prior knowledge of
the resource ID mapping or it can query device for it.

Software version and dependencies
.................................

  .. libdeps::

Related application notes
.........................

The following application notes use this library:

  * ANxxxx - [App note title 1]
  * ANxxxx - [App note title 2]
  ...
