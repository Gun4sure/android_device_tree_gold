/*
 * Copyright (C) 2021 The Android Open Source Project
 * Copyright (C) 2022-2026 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <android-base/logging.h>
#include <android/binder_interface_utils.h>
#include <health-impl/Health.h>
#include <health/utils.h>

#ifndef CHARGER_FORCE_NO_UI
#define CHARGER_FORCE_NO_UI 0
#endif

#if !CHARGER_FORCE_NO_UI
#include <health-impl/ChargerUtils.h>
#endif

using aidl::android::hardware::health::HalHealthLoop;
using aidl::android::hardware::health::Health;

#if !CHARGER_FORCE_NO_UI
using aidl::android::hardware::health::charger::ChargerCallback;
using aidl::android::hardware::health::charger::ChargerModeMain;
#endif

namespace {

constexpr char kInstanceName[] = "default";
constexpr std::string_view kChargerArg{"--charger"};

#if !CHARGER_FORCE_NO_UI
class ChargerCallbackImpl final : public ChargerCallback {
  public:
    using ChargerCallback::ChargerCallback;
    bool ChargerEnableSuspend() override { return true; }
};
#endif

}  // namespace

int main(int argc, char** argv) {
#ifdef __ANDROID_RECOVERY__
    android::base::InitLogging(argv, android::base::KernelLogger);
#endif

    auto config = std::make_unique<healthd_config>();
    ::android::hardware::health::InitHealthdConfig(config.get());
    auto binder = ndk::SharedRefBase::make<Health>(kInstanceName, std::move(config));

    if (argc >= 2 && argv[1] == kChargerArg) {
#if !CHARGER_FORCE_NO_UI
        return ChargerModeMain(binder, std::make_shared<ChargerCallbackImpl>(binder));
#endif

        LOG(INFO) << "Starting charger mode without UI.";
    } else {
        LOG(INFO) << "Starting gold health HAL.";
    }

    auto halHealthLoop = std::make_shared<HalHealthLoop>(binder, binder);
    return halHealthLoop->StartLoop();
}
