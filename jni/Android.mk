LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE    := ksu_hide_root
LOCAL_SRC_FILES := hide_root.cpp
LOCAL_C_INCLUDES := $(LOCAL_PATH)
LOCAL_LDLIBS    := -ldl
include $(BUILD_SHARED_LIBRARY)
