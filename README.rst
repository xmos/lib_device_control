Device Control Library
======================

Summary
-------

The Device Control Library provides configuration and control from a host to an XMOS device 
over a number of transport layers.

Features
........

  * Simple read/write API
  * Includes different transports including I2C slave, USB requests or xSCOPE over xCONNECT
  * Supports multiple resources per task

Typical resource usage
......................

Less than 1KB of code space is needed. The API is in the form of function calls,
so no additional logical cores are consumed. I/O requirements depend on which transport
layer is used.

Software version and dependencies
.................................

  .. libdeps::

Related application notes
.........................

   AN01034 - Using the Device Control Library over USB

