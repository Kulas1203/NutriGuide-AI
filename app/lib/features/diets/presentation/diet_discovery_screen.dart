import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../profile/application/profile_controller.dart';
import '../domain/diet_catalog.dart';
import '../domain/diet_program.dart';

/// Diet discovery with up-to-three comparison (master requirement §6).
class DietDiscoveryScreen extends ConsumerStatefulWidget {
  const DietDiscoveryScreen({super.key});

  @override
  ConsumerState<DietDiscoveryScreen> createState() =>
      _DietDiscoveryScreenState();
}

class _DietDiscoveryScreenState extends ConsumerState<DietDiscoveryScreen> {
  final Set<String> _compare = {};

  void _toggleCompare(String id) {
    setState(() {
      if (_compare.contains(id)) {
        _compare.remove(id);
      } else if (_compare.length < 3) {
        _compare.add(id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can compare up to three diets.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDiet = ref.watch(profileControllerProvider).profile?.dietId;
    return Scaffold(
      appBar: AppBar(title: const Text('Explore diets')),
      floatingActionButton: _compare.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () => _showComparison(context),
              icon: const Icon(Icons.compare_arrows_rounded),
              label: Text('Compare ${_compare.length}'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          NGSpacing.lg,
          NGSpacing.lg,
          NGSpacing.lg,
          96,
        ),
        children: [
          Text(
            'Each approach can work — the best diet is one you can keep up. '
            'Tap to learn more, or select up to three to compare.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: NGSpacing.lg),
          for (final diet in DietCatalog.all) ...[
            _DietTile(
              diet: diet,
              isCurrent: diet.id == currentDiet,
              selectedForCompare: _compare.contains(diet.id),
              onCompareToggle: () => _toggleCompare(diet.id),
              onTap: () => context.push('/diets/${diet.id}'),
            ),
            const SizedBox(height: NGSpacing.md),
          ],
        ],
      ),
    );
  }

  void _showComparison(BuildContext context) {
    final diets = _compare.map(DietCatalog.byId).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, controller) =>
            _ComparisonView(diets: diets, scrollController: controller),
      ),
    );
  }
}

class _DietTile extends StatelessWidget {
  const _DietTile({
    required this.diet,
    required this.isCurrent,
    required this.selectedForCompare,
    required this.onCompareToggle,
    required this.onTap,
  });

  final DietProgram diet;
  final bool isCurrent;
  final bool selectedForCompare;
  final VoidCallback onCompareToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NGCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(diet.name, style: theme.textTheme.titleMedium),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NGSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: NGRadius.chip,
                  ),
                  child: Text(
                    'Current',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: NGSpacing.xs),
          Text(diet.tagline, style: theme.textTheme.bodySmall),
          const SizedBox(height: NGSpacing.md),
          Row(
            children: [
              _MiniStat(label: 'Sustainability', value: diet.sustainability),
              const SizedBox(width: NGSpacing.lg),
              _MiniStat(label: 'Difficulty', value: diet.difficulty),
              const Spacer(),
              FilterChip(
                label: const Text('Compare'),
                selected: selectedForCompare,
                onSelected: (_) => onCompareToggle(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              i < value ? Icons.circle : Icons.circle_outlined,
              size: 8,
              color: i < value
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparisonView extends StatelessWidget {
  const _ComparisonView({required this.diets, required this.scrollController});

  final List<DietProgram> diets;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(NGSpacing.lg),
      children: [
        Text('Compare diets', style: theme.textTheme.headlineSmall),
        const SizedBox(height: NGSpacing.lg),
        _row(
          context,
          'Approach',
          diets.map((d) => d.name).toList(),
          header: true,
        ),
        _row(context, 'Best for', diets.map((d) => d.benefits.first).toList()),
        _row(
          context,
          'Watch out for',
          diets.map((d) => d.limitations.first).toList(),
        ),
        _row(
          context,
          'Sustainability',
          diets.map((d) => '${d.sustainability}/5').toList(),
        ),
        _row(
          context,
          'Difficulty',
          diets.map((d) => '${d.difficulty}/5').toList(),
        ),
        _row(
          context,
          'Common gaps',
          diets.map((d) => d.nutrientGaps.join(', ')).toList(),
        ),
        const SizedBox(height: NGSpacing.lg),
        Text(
          'This comparison is educational. If a diet lists people who should '
          'seek guidance first and that includes you, please check with a '
          'professional before starting.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    List<String> values, {
    bool header = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NGSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: NGSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final v in values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: NGSpacing.sm),
                    child: Text(
                      v,
                      style: header
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: NGSpacing.lg),
        ],
      ),
    );
  }
}
