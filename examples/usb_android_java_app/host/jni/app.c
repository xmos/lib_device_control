#include <stdlib.h>
#include "jni.h"
#include "android/log.h"
#include "libusb.h"
#include "control_host_support.h"
#include "defines.h"

#define TIMEOUT_MS 100

JNIEXPORT jint JNICALL
Java_example_DeviceControl_DeviceControl_get_ids(JNIEnv *env, jobject obj)
{
  return (jint)(((PRODUCT_ID & 0xFFFF) << 16) | (VENDOR_ID & 0xFFFF));
}

JNIEXPORT jint JNICALL
Java_example_DeviceControl_DeviceControl_connect(JNIEnv *env, jobject obj,
                                                 jint fd, jintArray handle)
{
  int ret;
  unsigned char data[64];
  libusb_device_handle *devh = NULL;
  
  ret = libusb_init(NULL);
  if (ret < 0) {
    __android_log_print(ANDROID_LOG_INFO, "DeviceControl",
      "libusb_init failed: %d\n", ret);
    return 1;
  }

  ret = libusb_wrap_sys_device(NULL, (intptr_t)fd, &devh);
  if (ret < 0) {
    __android_log_print(ANDROID_LOG_INFO, "DeviceControl",
      "libusb_wrap_sys_device failed: %d\n", ret);
    return 2;
  }
  else if (devh == NULL) {
    __android_log_print(ANDROID_LOG_INFO, "DeviceControl",
      "libusb_wrap_sys_device returned invalid handle\n");
    return 3;
  }

  __android_log_print(ANDROID_LOG_INFO, "DeviceControl",
    "libusb_control_transfer start\n");

  ret = libusb_control_transfer(devh,
    LIBUSB_ENDPOINT_IN | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, CONTROL_GET_VERSION, CONTROL_SPECIAL_RESID,
    data, sizeof(control_version_t), TIMEOUT_MS);

  __android_log_print(ANDROID_LOG_INFO, "DeviceControl",
    "libusb_control_transfer end: %d\n", ret);

  if (ret != sizeof(control_version_t)) {
    __android_log_print(ANDROID_LOG_INFO, "DeviceControl",
      "libusb_control_transfer failed: %d\n", ret);
    libusb_close(devh);
    libusb_exit(NULL);
    return 4;
  }

  { int expected = CONTROL_VERSION;
    if (memcmp(&expected, data, sizeof(control_version_t)) != 0) {
      __android_log_print(ANDROID_LOG_INFO, "DeviceControl",
        "device control library version mismatch\n");
      libusb_close(devh);
      libusb_exit(NULL);
      return 5;
    }
  }

  jint *body = (*env)->GetIntArrayElements(env, handle, 0);
  body[0] = (jint)devh;
  (*env)->ReleaseIntArrayElements(env, handle, body, 0);

  return 0;
}

JNIEXPORT jint JNICALL
Java_example_DeviceControl_DeviceControl_write_cmd(JNIEnv *env, jobject obj,
                                                   jint handle, jbyte value)
{
  unsigned char data[1] = { value };
  int ret = libusb_control_transfer((libusb_device_handle*)(intptr_t)handle,
    LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, CONTROL_CMD_SET_WRITE(0), RESOURCE_ID,
    data, 1, TIMEOUT_MS);

  __android_log_print(ANDROID_LOG_INFO, "DeviceControl",
    "libusb_control_transfer end: %d\n", ret);

  if (ret != 1) {
    __android_log_print(ANDROID_LOG_INFO, "DeviceControl",
      "libusb_control_transfer failed: %d\n", ret);
    return 1;
  }

  return 0;
}

JNIEXPORT jint JNICALL
Java_example_DeviceControl_DeviceControl_read_cmd(JNIEnv *env, jobject obj,
                                                  jint handle, jbyteArray values)
{
  unsigned char data[2];
  int ret = libusb_control_transfer((libusb_device_handle*)(intptr_t)handle,
    LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
    0, CONTROL_CMD_SET_READ(0), RESOURCE_ID,
    data, 2, TIMEOUT_MS);

  __android_log_print(ANDROID_LOG_INFO, "DeviceControl",
    "libusb_control_transfer end: %d\n", ret);

  if (ret != 2) {
    __android_log_print(ANDROID_LOG_INFO, "DeviceControl",
      "libusb_control_transfer failed: %d\n", ret);
    return 1;
  }

  jbyte *body = (*env)->GetByteArrayElements(env, values, 0);
  body[0] = (jbyte)data[0];
  body[1] = (jbyte)data[1];
  (*env)->ReleaseByteArrayElements(env, values, body, 0);

  return 0;
}

JNIEXPORT void JNICALL
Java_example_DeviceControl_DeviceControl_disconnect(JNIEnv *env, jobject obj,
                                                    jint handle)
{
  libusb_close((libusb_device_handle*)(intptr_t)handle);
  libusb_exit(NULL);
}
