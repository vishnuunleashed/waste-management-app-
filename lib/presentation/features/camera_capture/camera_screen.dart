import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../riverpod/camera/camera_notifier.dart';
import '../../riverpod/camera/camera_state.dart';
import '../processing/processing_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? selectedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (selectedFile != null && mounted) {
        _navigateToProcessing(selectedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery pick error: $e')),
        );
      }
    }
  }

  void _navigateToProcessing(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(imagePath: imagePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Camera viewfinder chrome intentionally stays dark regardless of
      // app theme, matching standard camera-UI convention (native camera
      // apps, Instagram, WhatsApp, etc. all keep a dark capture screen).
      backgroundColor: AppColors.dark.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Sliver Header (Hardware & Cloud Tier Badge)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const _HeaderBadge(),
                    const _FlashButton(),
                  ],
                ),
              ),
            ),

            // 2. Main Viewfinder Fill Remaining Sliver with Isolated RepaintBoundary
            SliverFillRemaining(
              hasScrollBody: false,
              child: Stack(
                children: [
                  const Positioned.fill(child: _Viewfinder()),

                  // Framing Target Guide Overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _FramingGuidePainter(color: AppTheme.accentMint),
                      ),
                    ),
                  ),

                  // Bottom Control Bar
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.dark.surfaceCard.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.dark.surfaceCardBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_library_rounded, size: 28),
                            color: AppColors.dark.textPrimary,
                            tooltip: 'Pick from Gallery',
                            onPressed: _pickImageFromGallery,
                          ),
                          _CaptureButton(onCaptured: _navigateToProcessing),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Watches only [CameraState.deviceCapability] — set once during camera
/// init and essentially never changes again, so isolating it here means
/// this badge never rebuilds for capture/flash toggles.
class _HeaderBadge extends ConsumerWidget {
  const _HeaderBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only used to gate the badge's presence today, but selecting it keeps
    // this widget decoupled from unrelated CameraState fields even if the
    // badge grows to show real capability info later.
    ref.watch(cameraProvider.select((s) => s.deviceCapability));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.primaryEmerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Ready to scan',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Watches only [CameraState.isFlashOn] — toggling flash no longer rebuilds
/// the viewfinder, capture button, or header.
class _FlashButton extends ConsumerWidget {
  const _FlashButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFlashOn = ref.watch(cameraProvider.select((s) => s.isFlashOn));

    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
      ),
      child: IconButton(
        icon: Icon(
          isFlashOn ? Icons.flash_on : Icons.flash_off,
          color: isFlashOn ? Colors.amber : Colors.white70,
        ),
        onPressed: () => ref.read(cameraProvider.notifier).toggleFlash(),
      ),
    );
  }
}

/// Watches only `(isReady, controller, errorMessage)` — the capture button
/// toggling `isCapturing` no longer rebuilds the preview.
class _Viewfinder extends ConsumerWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = ref.watch(cameraProvider.select((s) => s.isReady));
    final controller = ref.watch(cameraProvider.select((s) => s.controller));

    if (isReady && controller != null) {
      return RepaintBoundary(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      );
    }
    return _CameraFallback(
      errorMessage: ref.watch(cameraProvider.select((s) => s.errorMessage)),
      onPickFromGallery: () => _pickImageFromGallery(context),
    );
  }

  static Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final selectedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (selectedFile != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProcessingScreen(imagePath: selectedFile.path)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery pick error: $e')),
        );
      }
    }
  }
}

/// Watches only [CameraState.isCapturing] — the single most latency-critical
/// flag in the app (toggles on every tap-to-capture) — so tapping the
/// shutter only rebuilds this small button, not the header, viewfinder, or
/// framing guide.
class _CaptureButton extends ConsumerWidget {
  final ValueChanged<String> onCaptured;

  const _CaptureButton({required this.onCaptured});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCapturing = ref.watch(cameraProvider.select((s) => s.isCapturing));
    final notifier = ref.read(cameraProvider.notifier);

    return GestureDetector(
      onTap: isCapturing
          ? null
          : () async {
              final path = await notifier.capturePhoto();
              if (path != null) onCaptured(path);
            },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryEmerald,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryEmerald.withAlpha(120),
              blurRadius: 16,
              spreadRadius: 2,
            )
          ],
        ),
        child: isCapturing
            ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 36,
              ),
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onPickFromGallery;

  const _CameraFallback({required this.errorMessage, required this.onPickFromGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_enhance_rounded,
                size: 72,
                color: AppTheme.accentMint,
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Viewfinder',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? 'Position waste item inside frame',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onPickFromGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.surfaceCard,
                  foregroundColor: AppTheme.accentMint,
                  side: BorderSide(color: context.colors.surfaceCardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Pick Image from Gallery'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FramingGuidePainter extends CustomPainter {
  final Color color;

  _FramingGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLength = 32.0;
    final rect = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.15,
      size.width * 0.76,
      size.height * 0.5,
    );

    // Top-Left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLength, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLength), paint);

    // Top-Right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerLength, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLength), paint);

    // Bottom-Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLength, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerLength), paint);

    // Bottom-Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerLength, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
