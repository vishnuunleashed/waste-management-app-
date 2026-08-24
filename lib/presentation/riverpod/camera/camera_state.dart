import 'package:camera/camera.dart';
import '../../../core/utils/device_capability_service.dart';

class CameraState {
  final bool isInitializing;
  final bool isReady;
  final bool isCapturing;
  final CameraController? controller;
  final List<CameraDescription> cameras;
  final int selectedCameraIndex;
  final bool isFlashOn;
  final DeviceCapability? deviceCapability;
  final String? errorMessage;

  const CameraState({
    required this.isInitializing,
    required this.isReady,
    required this.isCapturing,
    this.controller,
    this.cameras = const [],
    this.selectedCameraIndex = 0,
    this.isFlashOn = false,
    this.deviceCapability,
    this.errorMessage,
  });

  CameraState copyWith({
    bool? isInitializing,
    bool? isReady,
    bool? isCapturing,
    CameraController? controller,
    List<CameraDescription>? cameras,
    int? selectedCameraIndex,
    bool? isFlashOn,
    DeviceCapability? deviceCapability,
    String? errorMessage,
  }) {
    return CameraState(
      isInitializing: isInitializing ?? this.isInitializing,
      isReady: isReady ?? this.isReady,
      isCapturing: isCapturing ?? this.isCapturing,
      controller: controller ?? this.controller,
      cameras: cameras ?? this.cameras,
      selectedCameraIndex: selectedCameraIndex ?? this.selectedCameraIndex,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      deviceCapability: deviceCapability ?? this.deviceCapability,
      errorMessage: errorMessage,
    );
  }
}
