Device control library change log
=================================

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

