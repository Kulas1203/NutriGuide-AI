import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../profile/application/profile_controller.dart';
import '../domain/energy_calculator.dart';

class TargetsScreen extends ConsumerWidget {
  const TargetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(profileControllerProvider);
    final targets = state.targets;

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition targets')),
      body: targets == null
          ? const EmptyState(
              icon: Icons.calculate_outlined,
              title: 'No targets yet',
              message: 'Complete your profile to calculate targets.',
            )
          : ListView(
              padding: const EdgeInsets.all(NGSpacing.lg),
              children: [
                NGCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: StatRing(
                          progress: 1,
                          label: '${targets.calories}',
                          sublabel: 'kcal / day',
                          size: 150,
                        ),
                      ),
                      const SizedBox(height: NGSpacing.lg),
                      _macroRow(
                        context,
                        'Protein',
                        targets.proteinG,
                        NGColors.proteinChart,
                      ),
                      _macroRow(
                        context,
                        'Carbohydrates',
                        targets.carbsG,
                        NGColors.carbChart,
                      ),
                      _macroRow(
                        context,
                        'Fat',
                        targets.fatG,
                        NGColors.fatChart,
                      ),
                      _macroRow(
                        context,
                        'Fiber',
                        targets.fiberG,
                        NGColors.fiberChart,
                      ),
                      const Divider(height: NGSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Water goal', style: theme.textTheme.bodyMedium),
                          Text(
                            '${targets.waterMl} ml',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                for (final warning in targets.warnings) ...[
                  const SizedBox(height: NGSpacing.md),
                  NoticeBanner(
                    severity:
                        warning == TargetWarning.professionalGuidanceAdvised
                        ? NoticeSeverity.caution
                        : NoticeSeverity.info,
                    message: warning.message,
                  ),
                ],
                const SizedBox(height: NGSpacing.lg),
                NGCard(
                  color: theme.colorScheme.surfaceContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.functions_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: NGSpacing.xs),
                          Text(
                            'How this was calculated',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: NGSpacing.sm),
                      Text(
                        targets.methodExplanation,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: NGSpacing.sm),
                      Text(
                        'Calculation version: ${targets.calcVersion}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NGSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => _adjust(context, ref, targets),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Adjust my targets'),
                ),
                const SizedBox(height: NGSpacing.sm),
                TextButton.icon(
                  onPressed: () => _recompute(context, ref),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset to recommended'),
                ),
              ],
            ),
    );
  }

  Widget _macroRow(BuildContext context, String label, int grams, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NGSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: NGSpacing.sm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text('$grams g', style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }

  Future<void> _adjust(
    BuildContext context,
    WidgetRef ref,
    NutritionTargets targets,
  ) async {
    final calorieController = TextEditingController(
      text: targets.calories.toString(),
    );
    final proteinController = TextEditingController(
      text: targets.proteinG.toString(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust targets'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: calorieController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Daily calories'),
            ),
            const SizedBox(height: NGSpacing.md),
            TextField(
              controller: proteinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Protein (g)'),
            ),
            const SizedBox(height: NGSpacing.md),
            Text(
              'We’ll confirm before applying. NutriGuide won’t let targets '
              'drop below the $defaultCalorieFloor kcal safety minimum.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final newCalories =
        int.tryParse(calorieController.text) ?? targets.calories;
    final newProtein = int.tryParse(proteinController.text) ?? targets.proteinG;
    if (newCalories < defaultCalorieFloor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'For safety we cannot set calories below $defaultCalorieFloor kcal.',
          ),
        ),
      );
      return;
    }
    // Rebalance carbs to keep energy consistent with the adjusted values.
    final fatKcal = targets.fatG * 9;
    final proteinKcal = newProtein * 4;
    final carbs = ((newCalories - proteinKcal - fatKcal) / 4)
        .clamp(0, double.infinity)
        .round();
    await ref
        .read(profileControllerProvider.notifier)
        .setTargets(
          targets.copyWith(
            calories: newCalories,
            proteinG: newProtein,
            carbsG: carbs,
            userAdjusted: true,
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Targets updated.')));
    }
  }

  Future<void> _recompute(BuildContext context, WidgetRef ref) async {
    await ref.read(profileControllerProvider.notifier).recompute();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Targets reset to recommended values.')),
      );
    }
  }
}
