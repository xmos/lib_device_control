:orphan:

##########################################
lib_device_control: Device Control Library
##########################################

:vendor: XMOS
:version: 5.0.1
:scope: General Use
:description: A library to control XMOS devices from a host
:category: General Purpose
:keywords: USB, Serial interface, IO
:devices: xcore-200, xcore.ai

*******
Summary
*******

The Device Control Library is a protocol layer that handles the routing of control messages between a host and one or
many controllable resources within the controlled device. The library is transport agnostic and can be used with
physical transports such as I2C, SPI, USB or XSCOPE.

********
Features
********

* Simple read/write API
* Fully acknowledged protocol
* Includes different transports including I2C slave, USB requests, XSCOPE over XCONNECT and SPI slave
* Supports multiple resources per task

The table below shows combinations of host and transport mechanisms that are currently supported. 
Adding new transport layers and/or hosts is straightforward where the hardware supports it.

.. list-table:: Supported Device Control Library Transports
 :header-rows: 1

 * - Host
   - I2C
   - USB
   - XSCOPE
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
   - Yes
   -
   - Yes*
 * - XCORE
   - Yes
   - 
   - 
   - 

Typical resource usage
======================

Less than 1KB of code space is needed for the target device, plus whatever the chosen transport
layer library requires. The API is in the form of function calls,
so no additional threads are consumed. I/O requirements also depend on which transport
layer is used.

************
Known issues
************

* No support for SPI on recent Raspberry Pi OS versions due to library compatibility issues.

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
