# On Google's kernel (GOLD_GKI=stock or latest), the vendor modules have to
# carry the symbol CRCs of Google's build, which for a few symbols differ from
# the ones of the kernel built here: the clang here takes __counted_by, which
# changes the CRCs of the interconnect calls (icc_*) without changing their ABI.
#
# kernel.mk builds this directory first among the external modules. Building it
# puts the entries of Google's build into the kernel's Module.symvers, keeping
# this build's entries for the in-tree modules that are not part of GKI.

GKI_SYMVERS := $(GOLD_GKI_DIR)/kernel_aarch64_Module.symvers

modules:
	awk -F '\t' 'NR == FNR { gki[$$2] = 1; print; next } !($$2 in gki)' \
		$(GKI_SYMVERS) $(OUT_DIR)/Module.symvers > $(OUT_DIR)/Module.symvers.gki
	mv $(OUT_DIR)/Module.symvers.gki $(OUT_DIR)/Module.symvers

modules_install clean:
	@:
