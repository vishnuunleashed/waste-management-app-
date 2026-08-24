import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/scan_history_repository.dart';
import '../../riverpod/classification/classification_notifier.dart';
import '../../riverpod/classification/classification_state.dart';
import '../result/result_screen.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const ProcessingScreen({super.key, required this.imagePath});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classificationProvider(widget.imagePath));

    ref.listen<ClassificationState>(
      classificationProvider(widget.imagePath),
      (previous, next) {
        if (!next.isLoading && next.wasteItem != null && mounted) {
          // Fire-and-forget: a history-save failure shouldn't block the
          // user from seeing their result.
          sl<ScanHistoryRepository>().saveScan(next.wasteItem!).then((result) {
            result.match(
              (failure) => debugPrint('Could not save scan to history: ${failure.message}'),
              (_) => null,
            );
          });
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ResultScreen(wasteItem: next.wasteItem!),
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Analyzing Item'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image Thumbnail Container with Emerald Scanning Beam Line
                  Container(
                    width: 260,
                    height: 320,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primaryEmerald, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryEmerald.withAlpha(80),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Builder(
                              builder: (context) {
                                // Decode at display resolution, not full camera
                                // resolution — this box is only 260x320 logical
                                // pixels, so decoding the source photo at native
                                // (often 12MP+) resolution just to downscale it
                                // for paint wastes real CPU/memory on every scan.
                                final dpr = MediaQuery.of(context).devicePixelRatio;
                                return Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.cover,
                                  cacheWidth: (260 * dpr).round(),
                                  cacheHeight: (320 * dpr).round(),
                                );
                              },
                            ),
                          ),

                          // Scanning Beam Line — the moving bar itself is
                          // wrapped in its own RepaintBoundary (nested inside
                          // Positioned, which must stay Stack's direct child)
                          // so its ~60fps animation doesn't force the static
                          // photo above to re-rasterize every frame for the
                          // whole duration of the scan.
                          AnimatedBuilder(
                            animation: _scanController,
                            builder: (context, child) {
                              return Positioned(
                                top: _scanController.value * 280,
                                left: 0,
                                right: 0,
                                child: child!,
                              );
                            },
                            child: RepaintBoundary(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentMint,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryEmerald.withOpacity(0.9),
                                      blurRadius: 12,
                                      spreadRadius: 4,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  if (state.errorMessage != null) ...[
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Try Again'),
                    )
                  ] else ...[
                    const CircularProgressIndicator(color: AppTheme.primaryEmerald),
                    const SizedBox(height: 24),
                    Text(
                      state.statusMessage,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dublin City Council Waste Classification Engine',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
