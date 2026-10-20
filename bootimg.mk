#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# The bootloader never loads boot.img's ramdisk, so the generic ramdisk goes into vendor_boot as
# stock's init_boot fragment. Soong refuses fragments other than "dlkm" and the Makefile resets
# the lists before reading device makefiles, so it is added here.
BOARD_VENDOR_RAMDISK_FRAGMENT.init_boot.PREBUILT := $(INSTALLED_RAMDISK_TARGET)
BOARD_VENDOR_RAMDISK_FRAGMENT.init_boot.MKBOOTIMG_ARGS := --ramdisk_type PLATFORM --ramdisk_name init_boot
INTERNAL_VENDOR_RAMDISK_FRAGMENTS += init_boot

gold_init_boot_fragment := \
    $(call build-prebuilt-vendor-ramdisk-fragment,init_boot,$(BOARD_VENDOR_RAMDISK_FRAGMENT.init_boot.PREBUILT))
INTERNAL_VENDOR_RAMDISK_FRAGMENT_TARGETS += $(gold_init_boot_fragment)
INTERNAL_VENDOR_RAMDISK_FRAGMENT_ARGS += \
    $(BOARD_VENDOR_RAMDISK_FRAGMENT.init_boot.MKBOOTIMG_ARGS) \
    --vendor_ramdisk_fragment $(gold_init_boot_fragment)
$(INSTALLED_VENDOR_BOOTIMAGE_TARGET): $(gold_init_boot_fragment)

# boot.img: the kernel alone.
INTERNAL_BOOTIMAGE_ARGS := $(filter-out --ramdisk $(INSTALLED_RAMDISK_TARGET),$(INTERNAL_BOOTIMAGE_ARGS))
INTERNAL_BOOTIMAGE_FILES := $(filter-out --%,$(INTERNAL_BOOTIMAGE_ARGS))

$(foreach b,$(INSTALLED_BOOTIMAGE_TARGET),$(eval $(call add-dependency,$(b),$(call bootimage-to-kernel,$(b)))))

$(INSTALLED_BOOTIMAGE_TARGET): $(MKBOOTIMG) $(AVBTOOL) $(INTERNAL_BOOTIMAGE_FILES) $(BOARD_AVB_BOOT_KEY_PATH)
	$(call pretty,"Target boot image: $@")
	$(call build_boot_from_kernel_avb_enabled,$@,$(call bootimage-to-kernel,$@))

$(call declare-container-license-metadata,$(INSTALLED_BOOTIMAGE_TARGET),SPDX-license-identifier-GPL-2.0-only SPDX-license-identifier-Apache-2.0,restricted notice,$(BUILD_SYSTEM)/LINUX_KERNEL_COPYING build/soong/licenses/LICENSE,"Boot Image",boot)
$(call declare-container-license-deps,$(INSTALLED_BOOTIMAGE_TARGET),$(INTERNAL_BOOTIMAGE_FILES),$(PRODUCT_OUT)/:/)
UNMOUNTED_NOTICE_VENDOR_DEPS += $(INSTALLED_BOOTIMAGE_TARGET)
