import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../profile/application/profile_controller.dart';
import '../domain/diet_catalog.dart';
import '../domain/diet_program.dart';

class DietDetailScreen extends ConsumerWidget {
  const DietDetailScreen({super.key, required this.dietId});

  final String dietId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diet = DietCatalog.byId(dietId);
    final theme = Theme.of(context);
    final profileState = ref.watch(profileControllerProvider);
    final isCurrent = profileState.profile?.dietId == diet.id;

    return Scaffold(
      appBar: AppBar(title: Text(diet.name)),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          NGSpacing.lg,
          NGSpacing.sm,
          NGSpacing.lg,
          MediaQuery.of(context).padding.bottom + NGSpacing.sm,
        ),
        child: FilledButton(
          onPressed: isCurrent ? null : () => _selectDiet(context, ref, diet),
          child: Text(isCurrent ? 'Your current diet' : 'Choose this diet'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NGSpacing.lg),
        children: [
          Text(diet.tagline, style: theme.textTheme.titleMedium),
          const SizedBox(height: NGSpacing.md),
          Text(diet.overview, style: theme.textTheme.bodyLarge),
          const SizedBox(height: NGSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ratingCard(
                  context,
                  'Sustainability',
                  diet.sustainability,
                ),
              ),
              const SizedBox(width: NGSpacing.md),
              Expanded(
                child: _ratingCard(context, 'Difficulty', diet.difficulty),
              ),
            ],
          ),
          if (diet.seekGuidanceFirst.isNotEmpty) ...[
            const SizedBox(height: NGSpacing.lg),
            NoticeBanner(
              severity: NoticeSeverity.caution,
              title: 'Who should get guidance first',
              message: diet.seekGuidanceFirst.join('\n• '),
            ),
          ],
          _section(context, 'Typical food pattern', body: diet.foodPattern),
          _bulletSection(context, 'Potential benefits', diet.benefits),
          _bulletSection(context, 'Important limitations', diet.limitations),
          _section(context, 'A sample day'),
          for (final entry in diet.sampleDay.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: NGSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(entry.key, style: theme.textTheme.labelMedium),
                  ),
                  Expanded(
                    child: Text(entry.value, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          _bulletSection(context, 'Foods encouraged', diet.encouraged),
          _bulletSection(context, 'Foods limited', diet.limited),
          _bulletSection(context, 'Common nutrient gaps', diet.nutrientGaps),
          _section(context, 'Evidence & sources'),
          for (final evidenceRef in diet.evidence)
            Padding(
              padding: const EdgeInsets.only(bottom: NGSpacing.sm),
              child: SourceCard(
                title: evidenceRef.title,
                source: evidenceRef.source,
                date: evidenceRef.year,
              ),
            ),
          const SizedBox(height: NGSpacing.md),
          Text(
            'Diet content version ${DietProgram.contentVersion}. Reviewed for '
            'general education; not a substitute for individual advice.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: NGSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _selectDiet(
    BuildContext context,
    WidgetRef ref,
    DietProgram diet,
  ) async {
    final controller = ref.read(profileControllerProvider.notifier);
    final profile = ref.read(profileControllerProvider).profile;
    if (profile == null) return;
    await controller.saveProfile(
      profile.copyWith(dietId: diet.id),
      recomputeTargets: true,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${diet.name} selected. Your history is kept.')),
    );
    context.pop();
  }

  Widget _ratingCard(BuildContext context, String label, int value) {
    final theme = Theme.of(context);
    return NGCard(
      padding: const EdgeInsets.all(NGSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: NGSpacing.sm),
          Row(
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(
                  i < value ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: i < value
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, {String? body}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: NGSpacing.xl, bottom: NGSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (body != null) ...[
            const SizedBox(height: NGSpacing.xs),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _bulletSection(
    BuildContext context,
    String title,
    List<String> items,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: NGSpacing.xl,
            bottom: NGSpacing.sm,
          ),
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: NGSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: NGSpacing.sm),
                  child: Icon(Icons.circle, size: 6),
                ),
                Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}
