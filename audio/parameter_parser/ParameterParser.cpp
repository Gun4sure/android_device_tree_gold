/*
 * SPDX-FileCopyrightText: 2023 The Android Open Source Project
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#include "ParameterParser.h"

namespace vendor::audio::parserservice {

using ::aidl::android::hardware::audio::core::VendorParameter;
using ParameterScope = ::aidl::android::media::audio::IHalAdapterVendorExtension::ParameterScope;

// MediaTek's audio HAL takes the legacy key-value strings as they are, the way stock's own
// translator hands them over: the whole string is the id of a single vendor parameter with an
// empty extension, and the id of the first parameter the HAL returns is the answer to a query.

::ndk::ScopedAStatus ParameterParser::parseVendorParameterIds(
        const ParameterScope&, const std::string& in_rawKeys,
        std::vector<std::string>* _aidl_return) {
    if (!in_rawKeys.empty()) {
        _aidl_return->push_back(in_rawKeys);
    }
    return ::ndk::ScopedAStatus::ok();
}

::ndk::ScopedAStatus ParameterParser::parseVendorParameters(
        const ParameterScope&, const std::string& in_rawKeysAndValues,
        std::vector<VendorParameter>* out_syncParameters, std::vector<VendorParameter>*) {
    if (!in_rawKeysAndValues.empty()) {
        VendorParameter parameter;
        parameter.id = in_rawKeysAndValues;
        out_syncParameters->push_back(std::move(parameter));
    }
    return ::ndk::ScopedAStatus::ok();
}

::ndk::ScopedAStatus ParameterParser::parseBluetoothA2dpReconfigureOffload(
        const std::string&, std::vector<VendorParameter>*) {
    return ::ndk::ScopedAStatus::ok();
}

::ndk::ScopedAStatus ParameterParser::parseBluetoothLeReconfigureOffload(
        const std::string&, std::vector<VendorParameter>*) {
    return ::ndk::ScopedAStatus::ok();
}

::ndk::ScopedAStatus ParameterParser::processVendorParameters(
        const ParameterScope&, const std::vector<VendorParameter>& in_parameters,
        std::string* _aidl_return) {
    if (!in_parameters.empty()) {
        *_aidl_return = in_parameters.front().id;
    }
    return ::ndk::ScopedAStatus::ok();
}

}  // namespace vendor::audio::parserservice
