import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/bin_assignment.dart';
import '../../../domain/entities/scan_record.dart';
import '../../riverpod/history/recent_scans_provider.dart';
import '../../riverpod/onboarding/onboarding_notifier.dart';
import '../bin_guide/bin_guide_screen.dart';
import '../camera_capture/camera_screen.dart';
import '../collection_schedule/collection_schedule_screen.dart';
import '../history/scan_detail_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final council = ref.watch(onboardingProvider).selectedCouncil.name;
    final recentScans = ref.watch(recentScansProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Waste Classifier',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_city_rounded,
                                size: 14, color: AppTheme.accentMint),
                            const SizedBox(width: 4),
                            Text(
                              council,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.settings_rounded, color: context.colors.textPrimary),
                      tooltip: 'Settings',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Primary "Scan Item" CTA — camera only opens when the user asks for it.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _ScanItemCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CameraScreen()),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _QuickLinkTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Bin Guide',
                  subtitle: 'Browse what goes in each bin',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BinGuideScreen()),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _QuickLinkTile(
                  icon: Icons.local_shipping_rounded,
                  title: 'Collection Schedule',
                  subtitle: 'This week\'s bin collection days',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CollectionScheduleScreen()),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                child: Text(
                  'Recent Scans',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  _historySubtitle(recentScans.valueOrNull),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: recentScans.when(
                  data: (scans) => scans.isEmpty
                      ? const _EmptyHistoryCard()
                      : Column(
                          children: [
                            for (final scan in scans)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ScanHistoryTile(scan: scan),
                              ),
                          ],
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, __) => _HistoryErrorCard(error: error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tells the user when their history window next rolls forward — the
/// oldest currently-visible scan is the next one to be cleared.
String _historySubtitle(List<ScanRecord>? scans) {
  if (scans == null || scans.isEmpty) {
    return 'Kept for 7 days, then cleared automatically.';
  }
  final soonest = scans.map((s) => s.expireAt).reduce((a, b) => a.isBefore(b) ? a : b);
  final daysLeft = soonest.difference(DateTime.now()).inDays;
  if (daysLeft <= 0) {
    return 'Kept for 7 days — your oldest scan clears shortly.';
  }
  return 'Kept for 7 days — your oldest scan clears in $daysLeft ${daysLeft == 1 ? 'day' : 'days'}.';
}

class _ScanItemCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanItemCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryEmerald, AppTheme.secondaryEmerald],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryEmerald.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan an Item',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Find the right bin in seconds',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.surfaceCardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accentMint, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _HistoryErrorCard extends StatelessWidget {
  final Object error;
  const _HistoryErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(height: 12),
          Text(
            'Couldn\'t load scan history',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.surfaceCardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, color: context.colors.textMuted, size: 32),
          const SizedBox(height: 12),
          Text(
            'No scans yet',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Items you scan will show up here.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ScanHistoryTile extends StatelessWidget {
  final ScanRecord scan;
  const _ScanHistoryTile({required this.scan});

  IconData get _icon {
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

  String get _relativeTime {
    final diff = DateTime.now().difference(scan.scannedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ScanDetailScreen(scan: scan)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.surfaceCardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: scan.binColor, shape: BoxShape.circle),
              child: Icon(_icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.objectName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scan.localBinName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              _relativeTime,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
