Example: Xscope
===============

//TODO document this example

Build example
-------------

.. note::
  
  Make sure xscope host app is installed, refer to the :doc:`host/README`.


Once the host app is installed, run the following command from the example folder: 

.. code-block:: console

  cmake -G "Unix Makefiles" -B build
  xmake -C build

Running example
---------------

.. code-block:: console

    # Device: run the xscope device application
    xrun --xscope-port localhost:10101 bin/xscope.xe
    # Host: run the xscope host application
    # (Windows)
    call "bin/xscope_host_app.exe"
    # (Linux, MacOS)
    ./bin/xscope_host_app

Output
------

//TODO document the output
