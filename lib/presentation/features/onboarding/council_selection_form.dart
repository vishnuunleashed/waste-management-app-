import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/council.dart';
import '../../riverpod/onboarding/council_lookup_notifier.dart';

/// Country + postcode/dropdown council picker, shared between onboarding
/// and the "Change Council" screen reached from Settings.
class CouncilSelectionForm extends ConsumerStatefulWidget {
  final Council selectedCouncil;
  final ValueChanged<Council> onSelected;

  const CouncilSelectionForm({
    super.key,
    required this.selectedCouncil,
    required this.onSelected,
  });

  @override
  ConsumerState<CouncilSelectionForm> createState() => _CouncilSelectionFormState();
}

class _CouncilSelectionFormState extends ConsumerState<CouncilSelectionForm> {
  late Country _country = widget.selectedCouncil.country;
  final _postcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame — mutating provider state
    // directly inside build() causes cascading rebuilds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_country == Country.ireland) {
        ref.read(councilLookupProvider.notifier).loadIrelandCouncils();
      } else {
        ref.read(councilLookupProvider.notifier).loadUkCouncils();
      }
    });
  }

  @override
  void dispose() {
    _postcodeController.dispose();
    super.dispose();
  }

  void _onCountryChanged(Country country) {
    setState(() => _country = country);
    if (country == Country.ireland) {
      ref.read(councilLookupProvider.notifier).loadIrelandCouncils();
    } else {
      ref.read(councilLookupProvider.notifier).loadUkCouncils();
    }
  }

  Future<void> _findUkCouncil() async {
    final council =
        await ref.read(councilLookupProvider.notifier).resolveUkPostcode(_postcodeController.text);
    if (council != null) widget.onSelected(council);
  }

  @override
  Widget build(BuildContext context) {
    final lookupState = ref.watch(councilLookupProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.location_city_rounded, size: 72, color: AppTheme.accentMint),
          const SizedBox(height: 24),
          Text(
            'Find your council',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Bin rules, colors, and collection days vary by council. We\'ll use this to give '
            'you correct, up-to-date disposal instructions.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _CountryToggle(
            selected: _country,
            onChanged: _onCountryChanged,
          ),
          const SizedBox(height: 20),
          if (_country == Country.uk) ...[
            _UkPostcodeLookup(
              controller: _postcodeController,
              isLoading: lookupState.isResolvingPostcode,
              error: lookupState.postcodeError,
              onSubmit: _findUkCouncil,
              resolvedCouncil:
                  widget.selectedCouncil.country == Country.uk ? widget.selectedCouncil : null,
            ),
            const SizedBox(height: 20),
            _CouncilDivider(),
            const SizedBox(height: 20),
            _SearchableCouncilDropdown(
              label: 'Or search all UK local authorities',
              isLoading: lookupState.isLoadingUkCouncils,
              councils: lookupState.ukCouncils,
              selected:
                  widget.selectedCouncil.country == Country.uk ? widget.selectedCouncil : null,
              onSelected: widget.onSelected,
            ),
          ] else
            _SearchableCouncilDropdown(
              label: 'Local authority',
              isLoading: lookupState.isLoadingIrelandCouncils,
              councils: lookupState.irelandCouncils,
              selected:
                  widget.selectedCouncil.country == Country.ireland ? widget.selectedCouncil : null,
              onSelected: widget.onSelected,
            ),
        ],
      ),
    );
  }
}

class _CountryToggle extends StatelessWidget {
  final Country selected;
  final ValueChanged<Country> onChanged;

  const _CountryToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CountryTab(
            label: 'Ireland',
            isSelected: selected == Country.ireland,
            onTap: () => onChanged(Country.ireland),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CountryTab(
            label: 'UK',
            isSelected: selected == Country.uk,
            onTap: () => onChanged(Country.uk),
          ),
        ),
      ],
    );
  }
}

class _CountryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountryTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryEmerald.withAlpha(40) : context.colors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryEmerald : context.colors.surfaceCardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isSelected ? AppTheme.primaryEmerald : context.colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _UkPostcodeLookup extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String? error;
  final VoidCallback onSubmit;
  final Council? resolvedCouncil;

  const _UkPostcodeLookup({
    required this.controller,
    required this.isLoading,
    required this.error,
    required this.onSubmit,
    required this.resolvedCouncil,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: 'UK postcode',
            hintText: 'e.g. SW1A 1AA',
            filled: true,
            fillColor: context.colors.surfaceCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Find my council'),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent)),
        ],
        if (resolvedCouncil != null) ...[
          const SizedBox(height: 16),
          _CouncilTile(name: resolvedCouncil!.name, isSelected: true, onTap: () {}),
        ],
      ],
    );
  }
}

class _CouncilDivider extends StatelessWidget {
  const _CouncilDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.colors.surfaceCardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: Theme.of(context).textTheme.labelSmall),
        ),
        Expanded(child: Divider(color: context.colors.surfaceCardBorder)),
      ],
    );
  }
}

/// A tappable field that opens a searchable full-screen-height picker —
/// used for both Ireland's 31 local authorities and the UK's 361, neither
/// of which is comfortably scannable in a plain unfiltered dropdown.
class _SearchableCouncilDropdown extends StatelessWidget {
  final String label;
  final bool isLoading;
  final List<Council> councils;
  final Council? selected;
  final ValueChanged<Council> onSelected;

  const _SearchableCouncilDropdown({
    required this.label,
    required this.isLoading,
    required this.councils,
    required this.selected,
    required this.onSelected,
  });

  Future<void> _openPicker(BuildContext context) async {
    final chosen = await showModalBottomSheet<Council>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CouncilSearchSheet(councils: councils, label: label),
    );
    if (chosen != null) onSelected(chosen);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: CircularProgressIndicator(),
      );
    }
    final matched = councils.any((c) => c.id == selected?.id) ? selected : null;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: context.colors.surfaceCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          suffixIcon: const Icon(Icons.search_rounded),
        ),
        child: Text(
          matched?.name ?? 'Tap to search',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: matched == null ? context.colors.textMuted : null,
              ),
        ),
      ),
    );
  }
}

class _CouncilSearchSheet extends StatefulWidget {
  final List<Council> councils;
  final String label;

  const _CouncilSearchSheet({required this.councils, required this.label});

  @override
  State<_CouncilSearchSheet> createState() => _CouncilSearchSheetState();
}

class _CouncilSearchSheetState extends State<_CouncilSearchSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.councils
        : widget.councils.where((c) => c.name.toLowerCase().contains(query)).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search councils...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: context.colors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No councils match "$_query"',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final council = filtered[index];
                        return ListTile(
                          title: Text(council.name, style: Theme.of(context).textTheme.bodyLarge),
                          onTap: () => Navigator.of(context).pop(council),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouncilTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _CouncilTile({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: context.colors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryEmerald : context.colors.surfaceCardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(name, style: Theme.of(context).textTheme.titleSmall),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryEmerald),
          ],
        ),
      ),
    );
  }
}
