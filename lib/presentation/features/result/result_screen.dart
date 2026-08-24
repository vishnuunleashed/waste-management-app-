import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/bin_assignment.dart';
import '../../../domain/entities/waste_item.dart';

class ResultScreen extends StatelessWidget {
  final WasteItem wasteItem;

  const ResultScreen({super.key, required this.wasteItem});

  @override
  Widget build(BuildContext context) {
    final bin = wasteItem.binAssignment;

    IconData binIcon;
    switch (bin.binType) {
      case BinType.greenRecycling:
        binIcon = Icons.recycling_rounded;
        break;
      case BinType.brownCompost:
        binIcon = Icons.eco_rounded;
        break;
      case BinType.blackGeneral:
        binIcon = Icons.delete_outline_rounded;
        break;
      case BinType.specialHazard:
        binIcon = Icons.warning_amber_rounded;
        break;
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Dynamic Collapsible Hero Bin SliverAppBar
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: bin.binColor,
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
                bin.localBinName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                color: bin.binColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(binIcon, size: 52, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bin.councilName.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Identified Item Breakdown Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildItemBreakdownCard(context, wasteItem),
            ),
          ),

          // 3. Preparation Instructions Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                'Disposal Instructions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),

          // 4. Preparation Instructions List using SliverList
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final step = bin.disposalSteps[index];
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
                          const Icon(Icons.check_circle_outline,
                              color: AppTheme.primaryEmerald, size: 20),
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
                childCount: bin.disposalSteps.length,
              ),
            ),
          ),

          // 5. Primary CTA Floating Action Button Sliver
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text(
                  'Scan Another Item',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemBreakdownCard(BuildContext context, WasteItem item) {
    final confidencePct = (item.confidenceScore * 100).toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Identified Item',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withOpacity(0.2),
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
            _buildDetailRow(context, 'Object Name', item.objectName, Icons.category_rounded),
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Material Type', item.materialType, Icons.widgets_rounded),
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Condition', item.condition, Icons.clean_hands_rounded),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'Classified via',
              item.source == ClassificationSource.local ? 'On-device (offline)' : 'Cloud',
              item.source == ClassificationSource.local
                  ? Icons.smartphone_rounded
                  : Icons.cloud_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accentMint),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ],
    );
  }
}
