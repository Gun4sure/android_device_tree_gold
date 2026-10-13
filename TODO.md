# To do

What is untested, wrong, not done or not possible on this device, beyond the rows of LineageOS's device support requirements. Those rows are in the [status table](https://github.com/Star-caorui/lineageos-gold#status).

## Not tested

- Fast charging
- USB OTG
- Dual SIM
- China Telecom SIM
- Wi-Fi calling, video calls

## Known issues

| | |
| --- | --- |
| Offline charging while an alarm is set | With an alarm set in the Clock app, a powered-off phone on a charger can show the Redmi logo over and over instead of the charging screen. With no alarm set it goes straight to the charging screen. Cause not found yet. |
| Fast charger on the lock screen | The lock screen does not say when the charger is a fast one. The charger driver does not report the standard current and voltage limits. |
| Add-ons across updates | Every update logs `Backuptool postinstall step failed. ret=32512`, and it is harmless. LineageOS's update_engine decides whether to run the add-on scripts by reading an ext4 mount count, and does so for every partition with a post-install step. For system it reads 0 and skips, which is right with no add-ons installed. For vendor, which is EROFS, the same bytes are not a mount count; it reads a large number, mounts vendor and fails to find the script there. Carrying real add-ons over an update has not been tried. |
| SELinux denials | Two have been logged now and then and not traced: the positioning daemon reading a property, the media provider at the root directory. No effect seen. |
| DNG photos | Decoding several DNG files at the same moment can crash the app, about once in twenty tries with four threads. It is a race in AOSP's DNG library and is not patched. |

## Not done

| | |
| --- | --- |
| 108 MP, portrait and 16 MP front photos | The camera HAL only offers them to the stock camera app, so the rear camera outputs 12 MP and the front 4 MP. Porting that app is not planned. |
| Stronger video stabilisation | It takes a patch to the camera app, and we do not carry one. |
| More screen-off gestures | Double tap and single tap are offered. The FocalTech touch driver also lists swipes and letters; nobody has checked that the touch firmware reports them. |
| Volume boost | Stock's 200% volume is switched on from MIUI's side. The audio HAL's own switches for it have not been tried. |
| Dolby, MiSound, spatial audio | Stock's effect libraries are not included. |
| Display and touch extras | DC dimming, colour modes and game-mode touch tuning are driven by MIUI services that are not included. |
| "Hey Google" with the screen off | Untested. The sound trigger HAL and the enrollment apps are stock's and in place, but trying it needs the Google app. |
| Xiaomi and Alexa wake words | The models are not included. |
| Per-carrier VoLTE settings | VoLTE is switched on for every carrier with a debug property. |
| Wi-Fi country code | wpa_supplicant is built without a driver command library, so the framework cannot hand the driver a country code. On the test unit the driver uses China's channel list by itself. |
| Wi-Fi SAR power reduction | Not active. On stock the trigger is not in the vendor image. |
| SAR and front colour sensors | Present, unused. |
| MPEG-4 and H.263 hardware encoding | Not ported. |
| Hotspot connection tracking | Closed TCP connections of hotspot clients stay in the kernel's table for up to five days, a behaviour of AOSP's tethering offload. No measurable cost, so not patched. |
| Offline charging screen | Wakes with the power key only, as in AOSP. |
| ADB in recovery | Not pre-authorised. |
| Status bar and cutout | The overflow dot has uneven space around it, and in landscape apps are inset on the cutout side only. Both are stock Android behaviour. |

## Not possible

| | |
| --- | --- |
| Always-on display | With the stock display driver the system cannot suspend while the panel shows anything, about 290 mA. Left out in favour of the wake gestures. |
| Hotspot on another band than Wi-Fi | There is a single Wi-Fi radio: while connected to 5 GHz Wi-Fi the hotspot can only use the same channel. |
| Wi-Fi 6 | The chip reports no HE capability. The link tops out at 433 Mbps. |
| Hotspot hardware offload | The modem's offload driver reports itself disabled. |
| Sunlight enhancement switch | The panel has one brightness range, and its upper half is the high brightness mode that auto-brightness already uses. |
| Key attestation with device IDs | Fails with `CANNOT_ATTEST_IDS`. Ordinary attestation works. |
