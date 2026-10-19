# Redmi Note 13 5G/13R Pro/POCO X6 Neo 5G (gold/iron) Device Tree

Device tree for LineageOS 24.0 (Android 17). It is checked out at `device/xiaomi/gold`.

| | |
| --- | --- |
| Releases, what works, tested models | [lineageos-gold](https://github.com/Star-caorui/lineageos-gold#readme) |
| Known issues, what is untested or not done | [ISSUES.md](https://github.com/Star-caorui/lineageos-gold/blob/main/ISSUES.md) |
| How to build | [local_manifests](https://github.com/Star-caorui/local_manifests/tree/lineage-24.0#readme) |
| Kernel and modules | Built from source by `build-kernel.sh` (the sources and how they compare with stock's: [android_kernel_xiaomi_gold_manifest](https://github.com/Star-caorui/android_kernel_xiaomi_gold_manifest#readme)), with Google's GKI (see [GKI builds](#gki-builds)) |
| Proprietary files | [android_vendor_xiaomi_gold](https://github.com/Star-caorui/android_vendor_xiaomi_gold/tree/lineage-24.0#readme) |

## Origin

Forked from [Dhterech's tree](https://github.com/Dhterech/android_device_xiaomi_gold) at `6c5bdc8` and maintained on its own since: [our commits](https://github.com/Star-caorui/android_device_xiaomi_gold/compare/6c5bdc8...lineage-24.0).

## Scripts

| Script | What it fills |
| --- | --- |
| `build-kernel.sh` | `device/xiaomi/gold-kernels`, before each build: builds the vendor modules, the device tree blob and its overlay from source and fetches Google's GKI builds. Run it from the top of the tree; `SKIP_KERNEL_SYNC=1` builds without syncing the sources first |
| `extract-files.py` | `vendor/xiaomi/gold`, kept as [android_vendor_xiaomi_gold](https://github.com/Star-caorui/android_vendor_xiaomi_gold/tree/lineage-24.0#regenerating), from the stock package |
| `fetch-gki.sh` | `device/xiaomi/gold-kernels/gki/<build>`, from one of Google's GKI builds; `build-kernel.sh` runs it for each build in `gki.sha256` (see [GKI builds](#gki-builds)) |

## Kernel modules

`modules/` lists which vendor modules go into the vendor ramdisk and `vendor_dlkm`, which of them load and in what order, and which of Google's GKI modules `system_dlkm` has. They started as stock's (OS3.0.5.0.VNQMIXM); `modules.load.vendor` also loads `wmt_drv.ko`, which the Wi-Fi, Bluetooth, GPS and FM drivers depend on, and no longer names Millet's modules.

## GKI builds

The kernel image and the `system_dlkm` modules are Google's GKI, not Xiaomi's: any later GKI build of the same KMI generation (`android15-8`) runs the same vendor modules. `build-kernel.sh` downloads each build `gki.sha256` lists, with `fetch-gki.sh`, which checks the downloads against their SHA-256 and keeps the GKI modules `modules/modules.load.system_dlkm` names. `GOLD_GKI` picks one:

| `GOLD_GKI` | Build |
| --- | --- |
| `stock` | 15511674, `6.6.118-android15-8-ge56cf6b09cca-ab15511674-4k` (`android15-6.6-2026-01_r34`), as stock ships it |
| `latest` | 16498190, `6.6.143-android15-8-g170954b20ad9-ab16498190-4k` (`android15-6.6-2026-10_r1`, [release builds](https://source.android.com/docs/core/architecture/kernel/gki-android15-6_6-release-builds)) |

Build 16498190 no longer has `tls.ko` (`CONFIG_TLS` is gone from `gki_defconfig`); nothing depends on it. For a newer build, `fetch-gki.sh <build id>` prints the lines to add to `gki.sha256`; then set `GOLD_GKI_LATEST` in `BoardConfig.mk`.

## Credits

| Who | For what |
| --- | --- |
| [Dhterech](https://github.com/Dhterech/android_device_xiaomi_gold) | The tree this one was forked from |
| xiaomi-mt6833-dev/device_xiaomi_mt6833-common, aeronruless (Telegram), linastorvaldz (GitHub) | Dhterech's tree is based on their work |
| mt6897-devs/device_xiaomi_duchamp, LineageOS/android_device_xiaomi_rosemary | Dhterech's references |
| claxten10's [mt6833-devs/android_device_xiaomi_gold](https://github.com/mt6833-devs/android_device_xiaomi_gold) | The tree Dhterech's is built on |

Our commits follow other trees in places. Each one says so in its message.

| Followed | In what |
| --- | --- |
| cristidclxvi's [android_device_xiaomi_camellia](https://github.com/cristidclxvi/android_device_xiaomi_camellia) | How double tap to wake is switched, and two Wi-Fi settings |
| LineageOS's [android_device_motorola_mt6768-common](https://github.com/LineageOS/android_device_motorola_mt6768-common) | The stock AIDL audio service, the IMS files, the mtkpower stubs, the GNSS declarations, the power hint for games, and the seven changes for LineageOS 24.0 by Nolen Johnson, Michael Bestas, Nicholas Lim, Elias Gheeraert, Mashopy and Giovanni Ricca |
| LineageOS's android_device_motorola_mt6879-common, android_device_xiaomi_rosemary and android_device_xiaomi_mt6768-common, and crDroid's android_device_xiaomi_everpal | What to take from the stock images and how |
| LineageOS's android_device_motorola_lamu | Building against a prebuilt kernel's headers |
| bengris32 | His patch for Motorola's ImsService, which ours repeats on this device's build of the app |
| Dhterech's [android_kernel_xiaomi_gold](https://github.com/Dhterech/android_kernel_xiaomi_gold) | Loading `wmt_drv.ko` from the vendor module list |

## License

```
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
```
