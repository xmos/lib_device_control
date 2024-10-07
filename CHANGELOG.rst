lib_device_control Change Log
=============================

5.0.0
-----

  * ADDED: Support for XTC Tools 15.3.0.
  * ADDED: Support for xcommon_cmake in library and examples.
  * CHANGED: Replace makefiles in examples with CMakeLists.txt files.
  * CHANGED: Update examples to support XCORE-VOICE-L71 board.
  * ADDED: Example with SPI slave interface.
  * CHANGED: Replace lib_usb with lib_xud in examples and tests.
  * CHANGED: Tidy-up libusb drivers.
  * REMOVED: Project files for xTIMEcomposer.
  * ADDED: Support for status check of write operations.
  * ADDED: Driver for SPI interface on Raspberry Pi.
  * CHANGED: Move the code shared between host and device side to separate files.
  * FIXED: Include guards in header files comply with the C standard.
  * FIXED: Windows host issue with pre-2013 Visual Studio Compiler and stdbool.h.

4.2.1
-----

  * FIXED: Some errors were being printed to stdout, now all use stderr. Common
    format also adopted

4.2.0
-----

  * CHANGED: XN files to support 15.x.x tools

4.1.0
-----

  * CHANGED: Use XMOS Public Licence Version 1

4.0.2
-----

  * CHANGED: Pin Python package versions
  * REMOVED: not necessary cpanfile

4.0.1
-----

  * CHANGED: Increase USB host timeout to 500ms

4.0.0
-----

  * CHANGED: Build files updated to support new "xcommon" behaviour in xwaf.

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
