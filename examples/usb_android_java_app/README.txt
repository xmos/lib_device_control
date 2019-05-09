Android app example
===================

Build
-----

xCORE application build is straigtforward

Android app built using both NDK and SDK installed

Supplied makefile demonstrates the use of dx, aapt and keytool in producting
the APK. This is based on examples online such as:

  https://jumpstartprogramming.com/posts/hello-world-for-android
  http://geosoft.no/development/android.html

At time of writing SDK version 24 was used and fixed in makefiles

Also, native code or USB are built for all architectures, and makefile picks
out ARM64 for packaging. You can change this in the makefile.

Notice that Android code refers to device control library (lots of '..') for
header defines such as default resource ID. The way this example is currently
embedded in the device control library, those references are correct. Update as
necessary in your derived code.

Install
-------

This is an installed application, not a command line utility to copy and run.
Shared libraries (eg libusb and the native code) are packaged inside the APK.
To install and install use eg pm as you normally would.

Run
---

Start and stop commands are included in makefile, eg:

  am start -n example.DeviceControl/.DeviceControl
  am force-stop example.DeviceControl

Android Nougat displays a permission prompt for the user click on. There is an
option to remember the setting, and it will indeed remember so it only has to
be done once for each build of the app. It is a nuisance and at time of writing
I don't have a solution.
