#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),gold)

# The kernel, the vendor modules, the device tree blob and its overlay are put into
# gold-kernels by build-kernel.sh.
# This is read by the build only, not when its variables are looked up, so that
# lunch and breakfast work before that.
ifeq ($(and $(wildcard $(TARGET_PREBUILT_KERNEL)),$(BOARD_VENDOR_KERNEL_MODULES),$(wildcard $(BOARD_PREBUILT_DTBIMAGE_DIR)/*.dtb),$(wildcard $(BOARD_PREBUILT_DTBOIMAGE))),)
    $(error The kernel, the vendor modules, the device tree blob or its overlay are missing: run $(LOCAL_PATH)/build-kernel.sh from the top of the tree first)
endif

endif
