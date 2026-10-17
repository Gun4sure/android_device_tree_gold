/*
 * Copyright (C) 2021 The Android Open Source Project
 * Copyright (C) 2022-2026 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/parseint.h>
#include <android-base/strings.h>
#include <android/binder_interface_utils.h>
#include <health-impl/Health.h>
#include <health/utils.h>

#ifndef CHARGER_FORCE_NO_UI
#define CHARGER_FORCE_NO_UI 0
#endif

#if !CHARGER_FORCE_NO_UI
#include <health-impl/ChargerUtils.h>
#endif

#include <algorithm>
#include <atomic>
#include <chrono>
#include <optional>
#include <thread>

using aidl::android::hardware::health::BatteryHealthData;
using aidl::android::hardware::health::HalHealthLoop;
using aidl::android::hardware::health::Health;
using aidl::android::hardware::health::HealthInfo;

#if !CHARGER_FORCE_NO_UI
using aidl::android::hardware::health::charger::ChargerCallback;
using aidl::android::hardware::health::charger::ChargerModeMain;
#endif

namespace {

constexpr char kInstanceName[] = "default";
constexpr std::string_view kChargerArg{"--charger"};
constexpr int32_t kDesignCapacityUah = 5000000;
constexpr int32_t kLargestPlausibleMahCounter = 20000;
constexpr char kChargeFull[] = "/sys/class/power_supply/battery/charge_full";
constexpr char kChargeFullDesign[] = "/sys/class/power_supply/battery/charge_full_design";

std::optional<int64_t> ReadInt(const std::string& path) {
    std::string value;
    int64_t out;
    if (!android::base::ReadFileToString(path, &value) ||
        !android::base::ParseInt(android::base::Trim(value), &out)) {
        return std::nullopt;
    }
    return out;
}

// The gauge has no state_of_health node, so AOSP's service reports 0. It does report the full
// charge it has learned and the design one.
int32_t StateOfHealth() {
    const auto full = ReadInt(kChargeFull);
    const auto design = ReadInt(kChargeFullDesign);
    if (!full || !design || *full <= 0 || *design <= 0) {
        return 0;
    }
    return static_cast<int32_t>(std::clamp<int64_t>(*full * 100 / *design, 0, 100));
}

bool ChargeCounterIsMah(int32_t chargeCounter, int32_t batteryLevel, int32_t fullChargeUah) {
    if (chargeCounter <= 0 || chargeCounter > kLargestPlausibleMahCounter || batteryLevel <= 0 ||
        fullChargeUah < 1000000) {
        return false;
    }

    const int64_t expectedChargeUah =
            static_cast<int64_t>(fullChargeUah) * batteryLevel / 100;
    const int64_t scaledChargeUah = static_cast<int64_t>(chargeCounter) * 1000;

    return scaledChargeUah >= expectedChargeUah / 4 &&
           scaledChargeUah <= expectedChargeUah * 4;
}

int32_t NormalizeChargeCounter(int32_t chargeCounter, int32_t batteryLevel,
                               int32_t fullChargeUah) {
    if (ChargeCounterIsMah(chargeCounter, batteryLevel, fullChargeUah)) {
        return chargeCounter * 1000;
    }
    return chargeCounter;
}

// The battery's own full charge capacity, or the design one until it reports a plausible one.
int32_t FullChargeUah(int32_t reportedUah) {
    return reportedUah >= 1000000 ? reportedUah : kDesignCapacityUah;
}

class GoldHealth final : public Health {
  public:
    using Health::Health;

    ndk::ScopedAStatus getChargeCounterUah(int32_t* out) override {
        auto status = Health::getChargeCounterUah(out);
        if (!status.isOk()) {
            return status;
        }

        int32_t batteryLevel = 0;
        auto capacityStatus = Health::getCapacity(&batteryLevel);
        if (capacityStatus.isOk()) {
            *out = NormalizeChargeCounter(*out, batteryLevel, FullChargeUah(fullChargeUah_));
        }
        return status;
    }

    ndk::ScopedAStatus getBatteryHealthData(BatteryHealthData* out) override {
        auto status = Health::getBatteryHealthData(out);
        if (status.isOk() && out->batteryStateOfHealth <= 0) {
            out->batteryStateOfHealth = StateOfHealth();
        }
        return status;
    }

  protected:
    void UpdateHealthInfo(HealthInfo* healthInfo) override {
        // Kept for getChargeCounterUah, which runs on a binder thread and gets no HealthInfo.
        fullChargeUah_ = healthInfo->batteryFullChargeUah;
        healthInfo->batteryChargeCounterUah =
                NormalizeChargeCounter(healthInfo->batteryChargeCounterUah,
                                       healthInfo->batteryLevel,
                                       FullChargeUah(healthInfo->batteryFullChargeUah));
        if (healthInfo->batteryHealthData &&
            healthInfo->batteryHealthData->batteryStateOfHealth <= 0) {
            healthInfo->batteryHealthData->batteryStateOfHealth = StateOfHealth();
        }
    }

  private:
    std::atomic<int32_t> fullChargeUah_{0};
};

#if !CHARGER_FORCE_NO_UI
class ChargerCallbackImpl final : public ChargerCallback {
  public:
    using ChargerCallback::ChargerCallback;
    bool ChargerEnableSuspend() override { return true; }
};

constexpr char kPanelDpms[] =
        "/sys/devices/platform/14000000.dispsys_config/drm/card0/card0-DSI-1/dpms";
constexpr char kBacklight[] = "/sys/devices/platform/mtk_leds/leds/lcd-backlight/brightness";
constexpr char kChargerBrightness[] = "1638";
// The backlight driver ignores a value equal to the last one it was given.
constexpr char kChargerBrightnessNudge[] = "1637";

// The panel comes back dark every time it is powered up, and the charger UI only blanks and
// unblanks it. Set the brightness again whenever the panel turns on.
void RestoreBacklightOnUnblank() {
    using namespace std::chrono_literals;

    bool wasOn = true;
    while (true) {
        std::string state;
        const bool on = android::base::ReadFileToString(kPanelDpms, &state) &&
                        android::base::StartsWith(state, "On");
        if (on && !wasOn) {
            // The first write can arrive before the panel accepts commands, and a second
            // write of the same value would be dropped by the driver.
            android::base::WriteStringToFile(kChargerBrightnessNudge, kBacklight);
            std::this_thread::sleep_for(300ms);
            if (!android::base::WriteStringToFile(kChargerBrightness, kBacklight)) {
                PLOG(ERROR) << "Failed to restore the backlight";
            }
        }
        wasOn = on;
        std::this_thread::sleep_for(200ms);
    }
}
#endif

}  // namespace

int main(int argc, char** argv) {
#ifdef __ANDROID_RECOVERY__
    android::base::InitLogging(argv, android::base::KernelLogger);
#endif

    auto config = std::make_unique<healthd_config>();
    ::android::hardware::health::InitHealthdConfig(config.get());
    auto binder = ndk::SharedRefBase::make<GoldHealth>(kInstanceName, std::move(config));

    if (argc >= 2 && argv[1] == kChargerArg) {
#if !CHARGER_FORCE_NO_UI
        std::thread(RestoreBacklightOnUnblank).detach();
        return ChargerModeMain(binder, std::make_shared<ChargerCallbackImpl>(binder));
#endif

        LOG(INFO) << "Starting charger mode without UI.";
    } else {
        LOG(INFO) << "Starting gold health HAL.";
    }

    auto halHealthLoop = std::make_shared<HalHealthLoop>(binder, binder);
    return halHealthLoop->StartLoop();
}
