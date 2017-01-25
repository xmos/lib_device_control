Device Control Library
======================

Summary
-------

The Device Control Library provides the ability to configure and control an XMOS device 
from a host over a number of transport layers.

Features
........

  * Simple read/write API
  * Fully acknowledged protocol
  * Includes different transports including I2C slave, USB requests or xSCOPE over xCONNECT
  * Supports multiple resources per task

The table below shows combinations of host and transport mechanisms that are currently supported. 
Adding new transport layers and/or hosts is straightforward where the hardware supports it.

.. list-table:: Supported Device Control Library Transports
 :header-rows: 1

 * - Host
   - I2C
   - USB
   - xSCOPE
 * - PC / Windows
   - 
   - Yes
   - Yes
 * - PC / OSX
   - Yes
   - Yes
   - Yes
 * - Raspberry Pi / Linux
   - Yes
   - TBD
   - 
 * - xCORE
   - Yes
   - 
   - 

Typical resource usage
......................

Less than 1KB of code space is needed for the target device, plus whatever the chosen transport
layer library requires. The API is in the form of function calls,
so no additional logical cores are consumed. I/O requirements also depend on which transport
layer is used.

Software version and dependencies
.................................

  .. libdeps::

Related application notes
.........................

   AN01034 - Using the Device Control Library over USB

