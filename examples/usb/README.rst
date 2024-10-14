
Using the Device Control Library over USB
=========================================

Summary
-------

The Device Control library provides an API and a set of communication layers that
provide a host to device control path which is agnostic of the actual transport used.

Multiple transport layers are provided as part of the library including I2C, xSCOPE over xCONNECT and USB.

This application note provides a worked example of using the USB transport layer to
implement a control path that allows a host program to query and set GPIO on the device hardware.

Software dependencies
.....................

For a list of direct dependencies, look for USED_MODULES in the Makefile.

Required hardware
.................

The example code provided by this application has been implemented
and tested to work on the Vocal Fusion board. It is also
know to work with other xCORE-200 based boards with a USB interface.

Prerequisites
.............

 * This document assumes familiarity with the XMOS xCORE architecture,
   the XMOS tool chain and the xC language. Documentation related to these
   aspects which are not specific to this application note are linked to in
   the references appendix.
