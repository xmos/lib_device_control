package example.DeviceControl;

import java.util.*;
import android.util.Log;
import android.os.Bundle;
import android.os.Handler;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.BroadcastReceiver;
import android.app.PendingIntent;
import android.app.Activity;
import android.app.Application;
import android.hardware.usb.*;

public class DeviceControl extends Activity {
  private static final String TAG = "DeviceControl";
  private static final String ACTION_USB_PERMISSION = "com.android.example.USB_PERMISSION";

  static {
    System.loadLibrary("app");
  }

  public native int get_ids();
  public native int connect(int fd, int handle[]);
  public native void disconnect(int handle);
  public native int write_cmd(int handle, char value);
  public native int read_cmd(int handle, char values[]);

  private UsbDevice device = null;
  private UsbDeviceConnection connection = null;

  private final BroadcastReceiver usbBroadcastReceiver = new BroadcastReceiver() {
    @Override
    public void onReceive(Context context, Intent intent) {
      Log.i(TAG, "onReceive");

      if (ACTION_USB_PERMISSION.equals(intent.getAction())) {
        synchronized (this) {
          UsbDevice deviceExtra = (UsbDevice)intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
          if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
            if (device != null) {
              UsbManager manager = (UsbManager)context.getSystemService(Context.USB_SERVICE);
              connection = manager.openDevice(device);
              (new Handler()).postDelayed(new TaskRunnable(), 0);
            }
          } 
        }
      }
    }

    protected void finalize() throws Throwable {
      Log.i(TAG, "finalize");

      if (connection != null) {
        connection.close();
      }
    }
  };

  private class TaskRunnable implements Runnable {
    @Override
    public void run() {
      Log.i(TAG, "run");

      assert connection != null;

      int handle[] = {0};
      int retVal = 0;

      int fileDescriptor = connection.getFileDescriptor();
      Log.i(TAG, "getFileDescriptor:" + fileDescriptor);

      Log.i(TAG, "app::connect(" + fileDescriptor + ")");
      retVal = connect(fileDescriptor, handle);
      Log.i(TAG, "app::connect: " + retVal);
      if (retVal != 0) {
        Log.i(TAG, "error");
        return;
      }
      Log.i(TAG, "handle = " + handle[0]);

      for (int i = 0; i < 12; i++) {
        Log.i(TAG, "app::write_cmd(" + i + ")");
        retVal = write_cmd(handle[0], (char)i);
        Log.i(TAG, "app::write_cmd: " + retVal);

        try {
          Thread.sleep(100);
        }
        catch (InterruptedException e) {}

        char buttonEvent[] = {0, 0};
        Log.i(TAG, "app::read_cmd()");
        read_cmd(handle[0], buttonEvent);
        Log.i(TAG, "app::read_cmd: " + buttonEvent[0] + " " + buttonEvent[1]);

        try {
          Thread.sleep(100);
        }
        catch (InterruptedException e) {}
      }

      disconnect(handle[0]);
    }
  }

  @Override
  public void onCreate(Bundle savedInstanceState) {
    Log.i(TAG, "onCreate");
    super.onCreate(savedInstanceState);

    registerReceiver(usbBroadcastReceiver, new IntentFilter(ACTION_USB_PERMISSION));
    UsbManager manager = (UsbManager)getApplicationContext().getSystemService(Context.USB_SERVICE);
    HashMap<String, UsbDevice> deviceList = manager.getDeviceList();
    Iterator<UsbDevice> it = deviceList.values().iterator();
    while (it.hasNext()) {
      device = it.next();
      Log.i(TAG, device.getDeviceName());
      Log.i(TAG, String.format("0x%X 0x%X", device.getVendorId(), device.getProductId()));
      int ids = get_ids();
      int vendorId = ids & 0xFFFF;
      int productId = (ids >> 16) & 0xFFFF;
      if (device.getVendorId() == vendorId && device.getProductId() == productId) {
        manager.requestPermission(device, PendingIntent.getBroadcast(this, 0, new Intent(ACTION_USB_PERMISSION), 0));
      }
    }
  }
}
