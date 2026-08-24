import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

enum DeviceTier {
  tierA, // Flagship / High-End (120Hz ProMotion/Flagship GPU, High RAM)
  tierB, // Mid-Range (Adreno GPU / Mid-range processor, Adaptive 60-90Hz)
  tierC, // Budget / Low-End (60Hz display, limited RAM)
}

class DeviceCapability {
  final DeviceTier tier;
  final String deviceName;
  final String hardwareModel;
  final bool isAdrenoGpu;
  final double targetFps;
  final bool isOfflineLlmSupported;

  const DeviceCapability({
    required this.tier,
    required this.deviceName,
    required this.hardwareModel,
    required this.isAdrenoGpu,
    required this.targetFps,
    required this.isOfflineLlmSupported,
  });

  @override
  String toString() =>
      'DeviceCapability(tier: $tier, device: $deviceName, targetFps: ${targetFps}fps, offlineLlm: $isOfflineLlmSupported)';
}

class DeviceCapabilityService {
  final DeviceInfoPlugin _deviceInfoPlugin;

  DeviceCapabilityService({DeviceInfoPlugin? deviceInfoPlugin})
      : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  /// Detect device hardware capability and assign Tier A, B, or C
  Future<DeviceCapability> getCapability() async {
    if (kIsWeb) {
      return const DeviceCapability(
        tier: DeviceTier.tierB,
        deviceName: 'Web Browser',
        hardwareModel: 'Web',
        isAdrenoGpu: false,
        targetFps: 60.0,
        isOfflineLlmSupported: false,
      );
    }

    if (Platform.isAndroid) {
      try {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        final manufacturer = androidInfo.manufacturer.toLowerCase();
        final hardware = androidInfo.hardware.toLowerCase();

        final bool isAdreno = hardware.contains('qcom') ||
            hardware.contains('adreno') ||
            manufacturer.contains('qualcomm');

        // Simple heuristic based on API level & manufacturer
        if (androidInfo.version.sdkInt >= 33 && !isAdreno) {
          return DeviceCapability(
            tier: DeviceTier.tierA,
            deviceName: '${androidInfo.manufacturer} ${androidInfo.model}',
            hardwareModel: androidInfo.hardware,
            isAdrenoGpu: isAdreno,
            targetFps: 120.0,
            isOfflineLlmSupported: true,
          );
        } else if (isAdreno || androidInfo.version.sdkInt >= 29) {
          return DeviceCapability(
            tier: DeviceTier.tierB,
            deviceName: '${androidInfo.manufacturer} ${androidInfo.model}',
            hardwareModel: androidInfo.hardware,
            isAdrenoGpu: isAdreno,
            targetFps: 60.0,
            isOfflineLlmSupported: true,
          );
        } else {
          return DeviceCapability(
            tier: DeviceTier.tierC,
            deviceName: '${androidInfo.manufacturer} ${androidInfo.model}',
            hardwareModel: androidInfo.hardware,
            isAdrenoGpu: isAdreno,
            targetFps: 60.0,
            // The offline classifier is a small (~20MB) bundled MobileNetV2
            // model with CPU-only inference — light enough to run fine on
            // budget/low-end hardware too.
            isOfflineLlmSupported: true,
          );
        }
      } catch (e) {
        debugPrint('Error getting Android device info: $e');
      }
    } else if (Platform.isIOS) {
      try {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        final model = iosInfo.utsname.machine.toLowerCase();

        final bool isPro = model.contains('pro') || model.contains('ipad');
        return DeviceCapability(
          tier: isPro ? DeviceTier.tierA : DeviceTier.tierB,
          deviceName: iosInfo.name,
          hardwareModel: iosInfo.utsname.machine,
          isAdrenoGpu: false,
          targetFps: isPro ? 120.0 : 60.0,
          isOfflineLlmSupported: true,
        );
      } catch (e) {
        debugPrint('Error getting iOS device info: $e');
      }
    }

    // Default desktop/emulator fallback
    return const DeviceCapability(
      tier: DeviceTier.tierA,
      deviceName: 'Development Platform',
      hardwareModel: 'Generic',
      isAdrenoGpu: false,
      targetFps: 120.0,
      isOfflineLlmSupported: true,
    );
  }
}
