:orphan:

##########################################
lib_device_control: Device Control Library
##########################################

:vendor: XMOS
:version: 5.0.0
:scope: General Use
:description: A template for making XMOS libraries
:category: General Purpose
:keywords: USB, Serial interface, IO
:devices: xcore-200, xcore.ai

*******
Summary
*******

The Device Control Library provides the ability to configure and control an XMOS device 
from a host over a number of transport layers.

********
Features
********

* Simple read/write API
* Fully acknowledged protocol
* Includes different transports including I2C slave, USB requests, xSCOPE over xCONNECT and SPI slave
* Supports multiple resources per task

The table below shows combinations of host and transport mechanisms that are currently supported. 
Adding new transport layers and/or hosts is straightforward where the hardware supports it.

.. list-table:: Supported Device Control Library Transports
 :header-rows: 1

 * - Host
   - I2C
   - USB
   - xSCOPE
   - SPI
 * - PC / Windows
   - 
   - Yes
   - Yes
   -
 * - PC / OSX
   -
   - Yes
   - Yes
   -
 * - Raspberry Pi / Linux
   - Yes
   - TBD
   -
   - Yes
 * - xCORE
   - Yes
   - 
   - 
   - 

Typical resource usage
......................

Less than 1KB of code space is needed for the target device, plus whatever the chosen transport
layer library requires. The API is in the form of function calls,
so no additional logical cores are consumed. I/O requirements also depend on which transport
layer is used.

************
Known issues
************

* None

****************
Development repo
****************

* `lib_device_control <https://www.github.com/xmos/lib_device_control>`_ (https://www.github.com/xmos/lib_device_control)

**************
Required tools
**************

* XMOS XTC Tools: 15.3.1

*********************************
Required libraries (dependencies)
*********************************

* `lib_logging <https://www.xmos.com/libraries/lib_logging>`_ (https://www.xmos.com/libraries/lib_logging)
* `lib_xassert <https://www.xmos.com/libraries/lib_xassert>`_ (https://www.xmos.com/libraries/lib_xassert)

*************************
Related application notes
*************************

* None

*******
Support
*******

This package is supported by XMOS Ltd. Issues can be raised against the software at
`www.xmos.com/support <https://www.xmos.com/support>`_ or using GitHub `issues <https://github.com/xmos/lib_device_control/issues>`_.
