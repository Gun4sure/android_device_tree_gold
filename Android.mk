#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),gold)

# The kernel and the vendor modules are put into gold-kernels by build-kernel.sh.
# This is read by the build only, not when its variables are looked up, so that
# lunch and breakfast work before that.
ifeq ($(and $(wildcard $(TARGET_PREBUILT_KERNEL)),$(BOARD_VENDOR_KERNEL_MODULES)),)
    $(error $(TARGET_PREBUILT_KERNEL) or the vendor modules are missing: run $(LOCAL_PATH)/build-kernel.sh from the top of the tree first)
endif

endif
