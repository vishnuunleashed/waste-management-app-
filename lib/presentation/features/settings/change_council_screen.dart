import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/council.dart';
import '../../riverpod/onboarding/onboarding_notifier.dart';
import '../onboarding/council_selection_form.dart';

/// Lets the user change their council after onboarding — reuses the same
/// country/postcode/dropdown picker shown during first-run setup.
class ChangeCouncilScreen extends ConsumerStatefulWidget {
  const ChangeCouncilScreen({super.key});

  @override
  ConsumerState<ChangeCouncilScreen> createState() => _ChangeCouncilScreenState();
}

class _ChangeCouncilScreenState extends ConsumerState<ChangeCouncilScreen> {
  late Council _pending;

  @override
  void initState() {
    super.initState();
    _pending = ref.read(onboardingProvider).selectedCouncil;
  }

  Future<void> _save() async {
    await ref.read(onboardingProvider.notifier).selectCouncil(_pending);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(onboardingProvider).selectedCouncil;
    final hasChanged = _pending != current;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: const Text('Change Council')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CouncilSelectionForm(
                selectedCouncil: _pending,
                onSelected: (council) => setState(() => _pending = council),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasChanged ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.colors.surfaceCardBorder,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
