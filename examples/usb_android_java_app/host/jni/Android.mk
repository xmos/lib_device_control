LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := libusb1.0
LOCAL_SRC_FILES := ../prebuilt/$(TARGET_ARCH_ABI)/libusb1.0.so
LOCAL_EXPORT_C_INCLUDES := ../prebuilt
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := app
LOCAL_SRC_FILES := app.c
LOCAL_LDLIBS := -llog
LOCAL_SHARED_LIBRARIES := libusb1.0
LOCAL_C_INCLUDES := ../.. \
  ../../../../../lib_device_control/lib_device_control/src \
  ../../../../../lib_device_control/lib_device_control/api
include $(BUILD_SHARED_LIBRARY)
