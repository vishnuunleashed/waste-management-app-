import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class BinGuideScreen extends StatelessWidget {
  const BinGuideScreen({super.key});

  static const _bins = [
    _BinInfo(
      name: 'Green Bin — Dry Recyclables',
      color: AppTheme.greenBinRecycling,
      icon: Icons.recycling_rounded,
      accepts: 'Clean paper, cardboard, rigid plastic bottles/containers, metal cans & tins.',
      avoid: 'Anything greasy, food-soiled, or wet — that goes in the black bin instead.',
    ),
    _BinInfo(
      name: 'Brown Bin — Food & Garden Waste',
      color: AppTheme.brownBinCompost,
      icon: Icons.eco_rounded,
      accepts: 'Food scraps, peelings, coffee grounds, garden/plant waste.',
      avoid: 'Plastic wrappers, non-compostable stickers, or bagged waste in plastic bags.',
    ),
    _BinInfo(
      name: 'Black / Grey Bin — General Waste',
      color: AppTheme.blackBinGeneral,
      icon: Icons.delete_outline_rounded,
      accepts: 'Anything that can\'t be recycled or composted, including contaminated recyclables.',
      avoid: 'Batteries, electronics, and hazardous items — take those to a civic amenity site.',
    ),
    _BinInfo(
      name: 'Civic Amenity Drop-off — Hazardous / E-Waste',
      color: AppTheme.hazardCivicAmenity,
      icon: Icons.warning_amber_rounded,
      accepts: 'Batteries, electronics, light bulbs, paint, and chemicals.',
      avoid: 'Never place these in a kerbside bin — take them to a civic amenity site instead.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: const Text('Bin Guide')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Dublin City Council — 3-Bin System',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 16),
          for (final bin in _bins)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _BinCard(info: bin),
            ),
        ],
      ),
    );
  }
}

class _BinInfo {
  final String name;
  final Color color;
  final IconData icon;
  final String accepts;
  final String avoid;

  const _BinInfo({
    required this.name,
    required this.color,
    required this.icon,
    required this.accepts,
    required this.avoid,
  });
}

class _BinCard extends StatelessWidget {
  final _BinInfo info;

  const _BinCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.surfaceCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: info.color, shape: BoxShape.circle),
                child: Icon(info.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  info.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoLine(label: 'Accepts', value: info.accepts, positive: true),
          const SizedBox(height: 8),
          _InfoLine(label: 'Avoid', value: info.avoid, positive: false),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool positive;

  const _InfoLine({required this.label, required this.value, required this.positive});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          positive ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 16,
          color: positive ? AppTheme.primaryEmerald : Colors.redAccent.shade100,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
