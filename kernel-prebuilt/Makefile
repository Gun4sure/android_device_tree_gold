# Stock modules used while gold's own drivers are being brought over to source.
#
# kernel.mk builds this directory last, as an external module. Building does
# nothing; installing puts stock files into the kernel's module tree:
#
# - GOLD_STOCK_MODULES have no source-built counterpart yet and are added,
# - GOLD_STOCK_REPLACEMENTS are built from source too, but stock modules above
#   depend on the stock build of them (their symbol CRCs differ), so the stock
#   file replaces the source-built one in place. trusted_mem and rpmb-mtk are
#   here as the trees build them for Trustonic's TEE, which gold does not have
#   (and turning Trustonic off does not build); stock's use GenieZone only.
#   xm_chg_dfs here is Redmi Pad SE's, which exports charger notifier calls
#   that stock's charger_class already has.
#   ufs-mediatek-mod is Xiaomi's (it reports to miev); the trees' one finds
#   the LUNs but no disk comes up, so first stage mount fails.
#   imgsensor_isp6s carries gold's camera sensor drivers; the trees' one has
#   Redmi Pad SE's, so no camera shows up.
#
# The files come from device/xiaomi/gold-kernel, where stock's vendor_boot and
# vendor_dlkm modules are kept. Each module comes off these lists as its
# source-built version can be used.
#
# The trees build many modules stock does not ship (other SoCs, test and dummy
# variants). Some export the same symbols as the real ones, and depmod may pick
# them as dependencies: scpsys-dummy pulled into vendor_boot clashes with
# mtk-scpsys and first stage init dies. So everything stock does not ship is
# removed before depmod runs.

GOLD_STOCK_DIR := $(abspath $(CURDIR)/../../gold-kernel)

GOLD_STOCK_MODULES := \
    miev.ko \
    adapter_class.ko \
    auth_battery.ko \
    battery_auth_class.ko \
    binder_prio.ko \
    charger_class.ko \
    cpumaxfreq.ko \
    ds28e30_verify.ko \
    focaltech_tp.ko \
    fpc1022_tee.ko \
    gf_spi_tee.ko \
    gt9916r.ko \
    hq_charger_sysfs.ko \
    hq_kallsyms.ko \
    hq_notifier.ko \
    hq_notify.ko \
    ln8000_charger.ko \
    mitee.ko \
    mt6359p_battery.ko \
    mt6360_pmu_chg.ko \
    mtk_battery_manager.ko \
    mtk_charger_algorithm_class.ko \
    mtk_charger_framework.ko \
    mtk_chg_type_det.ko \
    mtk_pd_adapter.ko \
    mtk_pd_charging.ko \
    mtk_pep.ko \
    mtk_pep20.ko \
    mtk_pep40.ko \
    mtk_pep50.ko \
    sc8551x_charger.ko \
    slg_verify.ko \
    stick_verify.ko

GOLD_STOCK_REPLACEMENTS := \
    extcon-mtk-usb.ko \
    imgsensor_isp6s.ko \
    rpmb-mtk.ko \
    rt_pd_manager.ko \
    tcpc_class.ko \
    tcpc_mt6360.ko \
    tcpci_late_sync.ko \
    trusted_mem.ko \
    ufs-mediatek-mod.ko \
    xiaomi_touch.ko \
    xm_chg_dfs.ko

KERNELRELEASE := $(shell cat $(OUT_DIR)/include/config/kernel.release)

# Stock's sec.ko is built here as mtk_sec.ko
GOLD_SHIPPED_MODULES := $(patsubst sec.ko,mtk_sec.ko,$(notdir $(wildcard \
    $(GOLD_STOCK_DIR)/vendor_ramdisk/*.ko \
    $(GOLD_STOCK_DIR)/vendor_dlkm/*.ko \
    $(GOLD_STOCK_DIR)/system_dlkm/lib/modules/*.ko)))
MODDIR = $(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE)

# vendor_boot's copy first, as both are the same where both exist
stock_file = ls $(GOLD_STOCK_DIR)/vendor_ramdisk/$$m $(GOLD_STOCK_DIR)/vendor_dlkm/$$m 2>/dev/null | head -1

modules:
	@:

modules_install:
	@# kernel.mk keeps the install tree between builds: drop what earlier runs left
	@find $(INSTALL_MOD_PATH)/lib/modules -mindepth 1 -maxdepth 1 ! -name $(KERNELRELEASE) -exec rm -rf {} +
	rm -rf $(MODDIR)/extra
	mkdir -p $(MODDIR)/extra
	@for m in $(GOLD_STOCK_MODULES); do \
		f=$$($(stock_file)); \
		[ -n "$$f" ] || { echo "missing stock $$m" >&2; exit 1; }; \
		cp "$$f" $(MODDIR)/extra/; \
	done
	@for m in $(GOLD_STOCK_REPLACEMENTS); do \
		f=$$($(stock_file)); \
		t=$$(find $(MODDIR) -name $$m | head -1); \
		[ -n "$$f" ] && [ -n "$$t" ] || { echo "cannot replace $$m (stock '$$f', built '$$t')" >&2; exit 1; }; \
		cp "$$f" "$$t"; \
	done
	@find $(MODDIR) -name '*.ko' | while read f; do \
		case " $(GOLD_SHIPPED_MODULES) " in *" $${f##*/} "*) ;; *) rm "$$f";; esac; \
	done

clean:
	@:
