Device control library change log
=================================

3.2.4
-----

  * Change to use lib_i2c 5.0.0

3.2.3
-----

  * Preprocessor flag to send channel activity over xSCOPE for debugging

3.2.2
-----

  * Use -Os for the whole library rather than -O3 (#45)
  * Fix return code of control_register_resources

3.2.1
-----

  * Fix an issue on Windows where xSCOPE connection hangs on Windows (#17871)
  * Fix an issue on Windows where first xSCOPE connection succeeds, but
    subsequent ones fail with "socket reply error" (#47)

3.2.0
-----

  * Updated XSCOPE and USB protocols for host applications
  * Improved error messages in host applications
  * Dummy LED OEN port in example applications
  * Document Windows 10 attestation signing of libusb driver

3.1.1
-----

  * Use Vocal Fusion board XN file in xSCOPE and USB examples

3.1.0
-----

  * Add SPI support for Raspberry Pi host
  * No longer down-shift I2C address on Raspberry Pi host

3.0.1
-----

  * Fixed incorrectly returned read data in xSCOPE example host code

3.0.0
-----

  * Replace xSCOPE and USB size limits in public API by runtime errors
  * xSCOPE API change - buffer type from 64 words to 256 bytes
  * Windows build fixes
  * xTIMEcomposer project files for AN01034 and xSCOPE examples
  * Documentation updates

2.0.2
-----

  * Added AN01034 application note based around USB transport example and xCORE
    Array Microphone board
  * Documentation updates
  * Increased test coverage

2.0.1
-----

  * Update XE232 XN file in I2C host example for tools version 14.2 (compute
    nodes numbered 0 and 2 rather than 0 and 1)

2.0.0
-----

  * Added the ability to select USB interface (Allows control from Windows)

1.0.0
-----

  * Initial version.

  * Changes to dependencies:

    - lib_logging: Added dependency 2.1.0

    - lib_xassert: Added dependency 2.0.1

