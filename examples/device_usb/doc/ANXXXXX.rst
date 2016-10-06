.. include:: ../../README.rst

|newpage|

Overview
--------

Introduction
............

The Device Control library provides an API and a set of communication layers that 
provide a host to device control scheme which is agnostic of the actual transport used.

Multiple transport layers are provided as part of the library including I2C, xSCOPE over xCONNECT and USB. 

This application note provides a worked example of using the USB transport layer to
provide a control path that allows a host program to query and set GPIO on the device hardware.

Block diagram
.............

.. figure:: images/block_diagram.*
   :width: 80%

   Application block diagram

The application uses a total of four logical cores. Two logical cores take care of handling USB stack 
(one for low level and one for Endpoint 0) and one logical core is used to run the button and LED server task.
The fourth logical core runs the application and communicates with the button/LED server task and EP0 from where
it receives and sends and receives commands from the host.

How to use the Device Control library
-------------------------------------

The Makefile
............

To start using the device control, you need to add ``lib_device_control`` to you Makefile::

  USED_MODULES = .. lib_device_control ...

This demo also uses the USB Device library (``lib_usb``) for access to USB and Mic Array Board Support
(``lib_mic_array_board_support``) for access to the buttons and LEDs on the hardware. So the Makefile also includes::

  USED_MODULES = .. lib_usb lib_mic_array_board_support ..


Includes
........

This application requires the system header that defines XMOS xCORE specific
defines for declaring and initialising hardware:

.. literalinclude:: main.xc
   :start-on: include <platform.h>
   :end-before: include "app.h"

The Device Control library library functions are defined in ``control.h``. This header must
be included in your code to use the library. Low level USB device functionality is provided by ``usb.h`` 
and the USB device functionality is provided by the API described in ``hid.h`` and it's associated descriptor
set in ``decriptors.h``.

The application 

Allocating hardware resources
.............................

An |I2C| master requires a clock and a data pin. On an xCORE the pins are
controlled by ``ports``. The application therefore declares two 1-bit ports:

.. literalinclude:: main.xc
   :start-on: port p_scl
   :end-on: port p_sda

Accelerometer defines
.....................

A number of defines are used for the accelerometer device address and
register numbers:

.. literalinclude:: main.xc
   :start-on: define FXOS8700EQ_I2C_ADDR 0x1E
   :end-on: define FXOS8700EQ_OUT_Z_MSB 0x5

Reading over Device Control
...........................

The ``read_acceleration()`` function is used to get an accelerometer reading
for a given axis. It uses the |I2C| master to read the MSB and LSB registers
and then combines their results into the 10-bit value for the specified axis.
Each register read is checked to ensure that it has completed correctly.

.. literalinclude:: main.xc
   :start-on: int read_acceleration
   :end-before: void accelerometer

The |I2C| ``read_reg()`` function takes the device address, the register number
to read and a variable in which to return whether the read was successful.

By default it is assumed that the device address, register number and data are
all 8-bit. The |I2C| library provides other functions with different data-width
operands. Refer to the library documentation for details.

Writing over Device Control
...........................

The core of the application is the ``accelerometer()`` function which starts
by writing to the accelerometer device to configure and then enable it:

.. literalinclude:: main.xc
   :start-on: void accelerometer
   :end-before: while (1)

|newpage|

After that it continually loops polling the accelerometer until it is ready
and then reading the values from the three axes and displaying the current
status.

.. literalinclude:: main.xc
   :start-on: while (1)
   :end-before: // End accelerometer

The print uses a ``\r`` to ensure that only a single line of the screen is used.

The application main() function
...............................

The ``main()`` function sets up the tasks in the application.

Firstly, the ``interfaces`` and ``channels`` are declared. In xC, channels provide a simple way of
passing data tokens between concurrent tasks, without the need to worry about route setup 
or low level token protocol. ``XUD`` is written using a channel interface and so requires 
this method of communicating.

.. literalinclude:: main.xc
   :start-on: chan c_ep_out[NUM_EP_OUT], c_ep_in[NUM_EP_IN];
   :end-before: interface control i_control[1];

The interfaces also provide a means of concurrent tasks communicating with each other. 
Interfaces add high level language features on top of the channels and allow remote
calling of methods using parameters and return values with the benefit of type checking.

Communication between the Endpoint 0 task and the LED and Button server is peformed using
interfaces.

.. literalinclude:: main.xc
   :start-on: interface control i_control[1];
   :end-before: par

The rest of the ``main()`` function starts all the tasks in parallel
using the xC ``par`` construct:

.. literalinclude:: main.xc
   :start-on: par
   :end-before: return 0

Note that ``xud()`` and ``endpoint0()`` are placed on ``USB_TILE`` which is ``tile[1]`` leaving 
``tile[0]`` completely free for the application. The ``mabs_button_and_led_server()`` task needs
to be placed on ``tile[0]`` because the GPIO connected to the LEDs and buttons reside on that
tile.

This code starts all of the tasks concurrently and they then communicate over the channels
and interfaces.

The application app() task
..........................



|appendix|
|newpage|

Demo Hardware Setup
-------------------

To run the demo, connect a USB cable to power the xCORE-200 eXplorerKIT
and plug the xTAG to the board and connect the xTAG USB cable to your
development machine.

.. figure:: images/hw_setup.*
   :width: 80%

   Hardware setup

|newpage|

Launching the demo application
------------------------------

Once the demo example has been built either from the command line using xmake or
via the build mechanism of xTIMEcomposer studio it can be executed on the xCORE-200
eXplorerKIT.

Once built there will be a ``bin/`` directory within the project which contains
the binary for the xCORE device. The xCORE binary has a XMOS standard .xe extension.

Launching from the command line
...............................

From the command line you use the ``xrun`` tool to download and run the code
on the xCORE device::

  xrun --xscope bin/AN00156_i2c_master_example.xe

Once this command has executed the application will be running on the
xCORE-200 eXplorerKIT.

Launching from xTIMEcomposer Studio
...................................

From xTIMEcomposer Studio use the run mechanism to download code to xCORE device.
Select the xCORE binary from the ``bin/`` directory, right click and go to Run
Configurations. Double click on xCORE application to create a new run configuration,
enable the xSCOPE I/O mode in the dialog box and then
select Run.

Once this command has executed the application will be running on the
xCORE-200 eXplorerKIT.

Running the application
.......................

Once the application is started using either of the above methods there should
be output printed to the console showing the x, y and z axis values and as you
move the development board these will change.

|newpage|

References
----------

.. nopoints::

  * XMOS Tools User Guide

    http://www.xmos.com/published/xtimecomposer-user-guide

  * XMOS xCORE Programming Guide

    http://www.xmos.com/published/xmos-programming-guide

  * XMOS |I2C| Library

    http://www.xmos.com/support/libraries/lib_i2c

|newpage|

Full source code listing
------------------------

Source code for main.xc
.......................

.. literalinclude:: main.xc
  :largelisting:

|newpage|
