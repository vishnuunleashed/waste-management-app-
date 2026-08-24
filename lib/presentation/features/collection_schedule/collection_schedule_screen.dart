import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/collection_schedule.dart';
import '../../riverpod/onboarding/onboarding_notifier.dart';
import '../../riverpod/schedule/council_schedule_provider.dart';

const _weekdayLabels = {
  'monday': 'Monday',
  'tuesday': 'Tuesday',
  'wednesday': 'Wednesday',
  'thursday': 'Thursday',
  'friday': 'Friday',
  'saturday': 'Saturday',
  'sunday': 'Sunday',
};

class CollectionScheduleScreen extends ConsumerWidget {
  const CollectionScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final council = ref.watch(onboardingProvider).selectedCouncil;
    final scheduleAsync = ref.watch(councilScheduleProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Collection Schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            council.name,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 16),
          scheduleAsync.when(
            data: (schedule) => _ScheduleBody(schedule: schedule),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            // No cache exists yet in this failure case (the initial load
            // itself failed), so retrying can't discard a valid cached
            // schedule — unlike a manual "refresh" action would.
            error: (error, _) => _ScheduleError(
              message: error.toString(),
              onRetry: () => ref.read(councilScheduleProvider.notifier).refresh(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleBody extends ConsumerWidget {
  final CollectionSchedule schedule;
  const _ScheduleBody({required this.schedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.accentMint.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentMint.withAlpha(80)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.accentMint, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  schedule.disclaimer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final day in weekdayOrder)
          if (schedule.days[day]?.collects == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DayCard(day: day, daySchedule: schedule.days[day]!),
            ),
        if (schedule.days.values.every((d) => !d.collects))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'No collection days found for this council.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => _showCorrectionDialog(context, ref),
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('This looks wrong'),
          ),
        ),
      ],
    );
  }

  Future<void> _showCorrectionDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.colors.surfaceCard,
        title: const Text('What looks wrong?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: Theme.of(dialogContext).textTheme.bodyLarge,
          decoration: const InputDecoration(
            hintText: 'e.g. "Recycling is actually on Tuesday, not Wednesday"',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (submitted != true || controller.text.trim().isEmpty) return;
    if (!context.mounted) return;

    final failure =
        await ref.read(councilScheduleProvider.notifier).reportCorrection(controller.text);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? 'Thanks — we\'ll review this. If another user reports the same issue, it '
                  'triggers an automatic refresh.'
              : 'Could not submit: ${failure.message}',
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String day;
  final DaySchedule daySchedule;

  const _DayCard({required this.day, required this.daySchedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.surfaceCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_rounded, color: AppTheme.primaryEmerald),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _weekdayLabels[day] ?? day,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  daySchedule.materials.isEmpty ? 'Materials unknown' : daySchedule.materials.join(', '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ScheduleError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: context.colors.textMuted, size: 40),
          const SizedBox(height: 12),
          Text(
            'Couldn\'t load the collection schedule.\n$message',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
