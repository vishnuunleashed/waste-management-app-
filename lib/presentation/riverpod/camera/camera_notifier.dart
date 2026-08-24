import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/device_capability_service.dart';
import 'camera_state.dart';

class CameraNotifier extends AutoDisposeNotifier<CameraState> {
  @override
  CameraState build() {
    ref.onDispose(() {
      state.controller?.dispose();
    });
    _initialize();
    return const CameraState(
      isInitializing: true,
      isReady: false,
      isCapturing: false,
    );
  }

  Future<void> _initialize() async {
    try {
      final capabilityService = sl<DeviceCapabilityService>();
      final capability = await capabilityService.getCapability();

      final availableCams = await availableCameras();
      if (availableCams.isEmpty) {
        state = state.copyWith(
          isInitializing: false,
          isReady: false,
          deviceCapability: capability,
          errorMessage: 'No physical camera hardware detected (Gallery mode available)',
        );
        return;
      }

      final controller = CameraController(
        availableCams[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      state = state.copyWith(
        isInitializing: false,
        isReady: true,
        controller: controller,
        cameras: availableCams,
        selectedCameraIndex: 0,
        deviceCapability: capability,
      );
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      final capability = await sl<DeviceCapabilityService>().getCapability();
      state = state.copyWith(
        isInitializing: false,
        isReady: false,
        deviceCapability: capability,
        errorMessage: 'Camera uninitialized or in fallback environment.',
      );
    }
  }

  Future<void> toggleFlash() async {
    if (state.controller == null || !state.isReady) return;
    try {
      final newFlashMode = state.isFlashOn ? FlashMode.off : FlashMode.torch;
      await state.controller!.setFlashMode(newFlashMode);
      state = state.copyWith(isFlashOn: !state.isFlashOn);
    } catch (e) {
      debugPrint('Flash toggle failed: $e');
    }
  }

  Future<String?> capturePhoto() async {
    if (state.controller == null || !state.isReady) return null;

    try {
      state = state.copyWith(isCapturing: true);
      final XFile photo = await state.controller!.takePicture();
      state = state.copyWith(isCapturing: false);
      return photo.path;
    } catch (e) {
      debugPrint('Photo capture failed: $e');
      state = state.copyWith(isCapturing: false, errorMessage: 'Capture failed: $e');
      return null;
    }
  }
}

final cameraProvider = NotifierProvider.autoDispose<CameraNotifier, CameraState>(() {
  return CameraNotifier();
});
