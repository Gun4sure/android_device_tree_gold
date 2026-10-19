#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),gold)

# The kernel, the vendor modules and the device tree blob are put into gold-kernels
# by build-kernel.sh.
# This is read by the build only, not when its variables are looked up, so that
# lunch and breakfast work before that.
ifeq ($(and $(wildcard $(TARGET_PREBUILT_KERNEL)),$(BOARD_VENDOR_KERNEL_MODULES),$(wildcard $(BOARD_PREBUILT_DTBIMAGE_DIR)/*.dtb)),)
    $(error The kernel, the vendor modules or the device tree blob are missing: run $(LOCAL_PATH)/build-kernel.sh from the top of the tree first)
endif

endif
