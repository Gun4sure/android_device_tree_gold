#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#
# Put gold's kernel into device/xiaomi/gold-kernels, where the build takes it from: the vendor
# modules and the device tree blob, built from source with android_kernel_xiaomi_gold_manifest,
# and Google's GKI builds.
# LineageOS's build_kernel does the same for the devices whose kernel manifests it hosts.
# Usage, from the top of the Android tree, before building:
#   device/xiaomi/gold/build-kernel.sh
#
#   SKIP_KERNEL_SYNC=1   build what out-kernel/gold has, without syncing it first
#   KERNEL_MANIFEST      a manifest snapshot of the sources (repo manifest -r) to sync instead of
#                        the branch, to build the modules of an earlier build again
#   JOBS                 parallel jobs (default: all CPUs)
#
# Needs what building a kernel needs (make, bc, flex, bison, libelf and OpenSSL headers), curl,
# sha256sum and python3 on the host.
set -euo pipefail

dev=device/xiaomi/gold
kdir=device/xiaomi/gold-kernels
[ -d "$dev" ] && [ -d "$kdir" ] && [ -d .repo/repo ] || {
    echo "Run this from the top of the Android tree." >&2
    exit 1
}
ktop=$PWD/out-kernel/gold

# The sources, in a tree of their own. repo is the Android tree's, which allows a repo init
# inside it, and the marker keeps the build system from scanning the tree.
if [ ! -d "$ktop/.repo" ]; then
    mkdir -p "$ktop/.repo"
    cp -R .repo/repo "$ktop/.repo/repo"
    touch "$ktop/.out-dir"
fi
[ -z "${KERNEL_MANIFEST:-}" ] || KERNEL_MANIFEST=$(readlink -f -- "$KERNEL_MANIFEST")
if [ "${SKIP_KERNEL_SYNC:-}" != 1 ]; then
    (cd "$ktop" &&
        repo init -q -u https://github.com/Star-caorui/android_kernel_xiaomi_gold_manifest \
            -b lineage-24.0 --depth=1 &&
        if [ -n "${KERNEL_MANIFEST:-}" ]; then
            cp "$KERNEL_MANIFEST" .repo/manifests/snapshot.xml && repo init -q -m snapshot.xml
        else
            repo init -q -m default.xml
        fi &&
        repo sync -q -c --detach --force-sync --no-tags)
fi
(cd "$ktop" && ./build_gold.sh)

# The vendor modules the lists name. The vendor ramdisk has those it loads, in normal boot or
# in recovery; vendor_dlkm has some that are loaded later, by name.
python3 - "$ktop/out/modules" "$kdir" <<'EOF'
import os, shutil, sys

built, kdir = sys.argv[1:]
names = lambda *lists: sorted({l.strip() for f in lists for l in open(os.path.join(kdir, f)) if l.strip()})
for part, mods in (('vendor_ramdisk', names('modules.load.vendor_ramdisk', 'modules.load.recovery')),
                   ('vendor_dlkm', names('modules.list.vendor_dlkm'))):
    missing = [m for m in mods if not os.path.exists(os.path.join(built, m))]
    if missing:
        sys.exit('not built: ' + ' '.join(missing))
    out = os.path.join(kdir, part)
    shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out)
    for m in mods:
        shutil.copy2(os.path.join(built, m), out)
    print('%s: %d modules' % (part, len(mods)))
EOF

# The device tree blob of vendor_boot
mkdir -p "$kdir/dtb"
cp "$ktop/out/dtb/gold.dtb" "$kdir/dtb/gold.dtb"

# Google's GKI builds, and a check that the vendor modules load on each
for id in $(awk '/^[0-9]/ { print $1 }' "$dev/gki.sha256" | sort -u); do
    [ -f "$kdir/gki/$id/kernel" ] || "$dev/fetch-gki.sh" "$id" "$kdir"
    python3 "$dev/check-kmi.py" "$kdir/gki/$id" "$kdir/vendor_ramdisk" "$kdir/vendor_dlkm"
done
echo "Kernel build output copied to $kdir/"
