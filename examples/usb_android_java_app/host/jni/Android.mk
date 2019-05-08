LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := app
LOCAL_SRC_FILES := app.c
LOCAL_SHARED_LIBRARIES += libusb1.0
LOCAL_LDLIBS := -llog
LOCAL_C_INCLUDES := ../.. \
  ../../../../../lib_device_control/lib_device_control/src \
  ../../../../../lib_device_control/lib_device_control/api

include $(BUILD_SHARED_LIBRARY)
include ../../../../../libusb/android/jni/libusb.mk # TODO precompiled
