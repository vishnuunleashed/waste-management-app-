import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/bin_assignment.dart';
import '../../../domain/entities/scan_record.dart';
import '../../../domain/entities/waste_item.dart' show ClassificationSource;

class ScanDetailScreen extends StatelessWidget {
  final ScanRecord scan;

  const ScanDetailScreen({super.key, required this.scan});

  IconData get _binIcon {
    switch (scan.binType) {
      case BinType.greenRecycling:
        return Icons.recycling_rounded;
      case BinType.brownCompost:
        return Icons.eco_rounded;
      case BinType.blackGeneral:
        return Icons.delete_outline_rounded;
      case BinType.specialHazard:
        return Icons.warning_amber_rounded;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final confidencePct = (scan.confidenceScore * 100).toInt();
    final daysUntilExpiry = scan.expireAt.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 230.0,
            floating: false,
            pinned: true,
            backgroundColor: scan.binColor,
            elevation: 4,
            flexibleSpace: FlexibleSpaceBar(
              // The title can wrap to 2 lines for long bin names (e.g.
              // "Black / Grey Bin (General Waste)"). It's bottom-anchored
              // by FlexibleSpaceBar, so the background content below is
              // pinned to the top instead of centered — that reserves
              // guaranteed clearance at the bottom regardless of how many
              // lines the title wraps to.
              titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
              title: Text(
                scan.localBinName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                color: scan.binColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      child: Icon(_binIcon, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scan.councilName.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withAlpha(220),
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Identified Item', style: Theme.of(context).textTheme.titleLarge),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryEmerald.withAlpha(50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryEmerald),
                            ),
                            child: Text(
                              '$confidencePct% Confidence',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.accentMint,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24, color: context.colors.surfaceCardBorder),
                      _DetailRow(label: 'Object Name', value: scan.objectName, icon: Icons.category_rounded),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Material Type', value: scan.materialType, icon: Icons.widgets_rounded),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Condition', value: scan.condition, icon: Icons.clean_hands_rounded),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Scanned',
                        value: _formatDate(scan.scannedAt),
                        icon: Icons.schedule_rounded,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Classified via',
                        value: scan.source == ClassificationSource.local
                            ? 'On-device (offline)'
                            : 'Cloud',
                        icon: scan.source == ClassificationSource.local
                            ? Icons.smartphone_rounded
                            : Icons.cloud_outlined,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (scan.disposalSteps.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text('Disposal Instructions', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final step = scan.disposalSteps[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.surfaceCardBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppTheme.primaryEmerald, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: context.colors.textPrimary,
                                      height: 1.4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: scan.disposalSteps.length,
                ),
              ),
            ),
          ],

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.surfaceCardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_delete_outlined, size: 18, color: context.colors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        daysUntilExpiry <= 0
                            ? 'This entry will be removed from your history shortly.'
                            : 'Removed from your history in $daysUntilExpiry '
                                '${daysUntilExpiry == 1 ? 'day' : 'days'} (on ${_formatDate(scan.expireAt)}).',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accentMint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ],
    );
  }
}
