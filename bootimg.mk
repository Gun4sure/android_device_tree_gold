#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Stock's vendor_boot ends with the generic ramdisk as a fragment called
# init_boot, and that is where /init comes from. The fragment is added here
# and not with BOARD_VENDOR_RAMDISK_FRAGMENTS because Soong refuses any
# fragment list other than "dlkm", also in builds that do not use its images.
INTERNAL_VENDOR_RAMDISK_FRAGMENTS += init_boot
BOARD_VENDOR_RAMDISK_FRAGMENT.init_boot.PREBUILT := $(INSTALLED_RAMDISK_TARGET)
BOARD_VENDOR_RAMDISK_FRAGMENT.init_boot.MKBOOTIMG_ARGS := --ramdisk_type PLATFORM --ramdisk_name init_boot
INTERNAL_VENDOR_RAMDISK_FRAGMENT_TARGETS += $(INSTALLED_RAMDISK_TARGET)
INTERNAL_VENDOR_RAMDISK_FRAGMENT_ARGS += \
    $(BOARD_VENDOR_RAMDISK_FRAGMENT.init_boot.MKBOOTIMG_ARGS) \
    --vendor_ramdisk_fragment $(INSTALLED_RAMDISK_TARGET)
$(INSTALLED_VENDOR_BOOTIMAGE_TARGET): $(INSTALLED_RAMDISK_TARGET)

# Stock's boot.img is the kernel alone.
$(INSTALLED_BOOTIMAGE_TARGET): $(MKBOOTIMG) $(AVBTOOL) $(strip $(call bootimage-to-kernel,$(INSTALLED_BOOTIMAGE_TARGET))) $(BOARD_AVB_BOOT_KEY_PATH)
	$(call pretty,"Target boot image: $@")
	$(MKBOOTIMG) --kernel $(strip $(call bootimage-to-kernel,$@)) \
	    $(INTERNAL_MKBOOTIMG_VERSION_ARGS) $(BOARD_MKBOOTIMG_ARGS) --output $@
	$(call assert-max-image-size,$@,$(call get-hash-image-max-size,$(call get-bootimage-partition-size,$@,boot)))
	$(AVBTOOL) add_hash_footer \
	    --image $@ \
	    $(call get-partition-size-argument,$(call get-bootimage-partition-size,$@,boot)) \
	    --salt `sha256sum "$(strip $(call bootimage-to-kernel,$@))" | cut -d " " -f 1` \
	    --partition_name boot $(INTERNAL_AVB_BOOT_SIGNING_ARGS) \
	    $(BOARD_AVB_BOOT_ADD_HASH_FOOTER_ARGS)
