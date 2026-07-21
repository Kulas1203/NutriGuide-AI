import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/utils/dates.dart';
import '../../fasting/application/fasting_controller.dart';
import '../../logging/application/diary_controller.dart';
import '../../logging/domain/food_item.dart';
import '../../planner/application/planner_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../progress/application/progress_controller.dart';
import '../../targets/domain/energy_calculator.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    final targets = profileState.targets;
    final diary = ref.watch(diaryControllerProvider);
    final online = ref.watch(connectivityProvider).asData?.value ?? true;

    if (profile == null || targets == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final consumed = diary.totals;
    final greeting = _greeting();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(diaryControllerProvider.notifier).load(diary.dayKey);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              NGSpacing.lg,
              NGSpacing.lg,
              NGSpacing.lg,
              NGSpacing.xxxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, ${profile.displayName}',
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          Dates.friendly(DateTime.now()),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.person_outline_rounded),
                    tooltip: 'Settings',
                  ),
                ],
              ),
              if (!online) ...[
                const SizedBox(height: NGSpacing.lg),
                const NoticeBanner(
                  severity: NoticeSeverity.caution,
                  message:
                      'You’re offline. Your logs are saved on this device and '
                      'will sync when you reconnect.',
                ),
              ],
              if (profile.requiresProfessionalGuidance) ...[
                const SizedBox(height: NGSpacing.lg),
                NoticeBanner(
                  severity: profile.hasUrgentSymptoms
                      ? NoticeSeverity.danger
                      : NoticeSeverity.caution,
                  title: profile.hasUrgentSymptoms ? 'Seek care now' : null,
                  message: profile.hasUrgentSymptoms
                      ? 'You noted urgent symptoms. If they are happening now, '
                            'contact local emergency services or seek immediate '
                            'care.'
                      : 'Based on your health profile, NutriGuide keeps '
                            'guidance general. Please work with a professional '
                            'for personalized care.',
                ),
              ],
              const SizedBox(height: NGSpacing.xl),
              _CaloriesCard(consumed: consumed, targets: targets),
              const SizedBox(height: NGSpacing.lg),
              Row(
                children: [
                  Expanded(child: _NextMealCard()),
                  const SizedBox(width: NGSpacing.md),
                  Expanded(child: _FastingCard()),
                ],
              ),
              const SizedBox(height: NGSpacing.lg),
              Row(
                children: [
                  Expanded(child: _WaterCard(target: targets.waterMl)),
                  const SizedBox(width: NGSpacing.md),
                  Expanded(child: _HabitCard()),
                ],
              ),
              const SizedBox(height: NGSpacing.lg),
              _CoachShortcut(),
              const SizedBox(height: NGSpacing.lg),
              _ProgressGlance(hideWeight: profile.hideWeightFeatures),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({required this.consumed, required this.targets});

  final Nutrients consumed;
  final NutritionTargets targets;

  @override
  Widget build(BuildContext context) {
    final remaining = (targets.calories - consumed.kcal).round();
    return NGCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatRing(
                progress: targets.calories == 0
                    ? 0
                    : consumed.kcal / targets.calories,
                label: '${consumed.kcal.round()}',
                sublabel: 'of ${targets.calories} kcal',
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: NGSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remaining >= 0
                            ? '$remaining kcal left'
                            : '${-remaining} kcal over',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: NGSpacing.md),
                      MacroBar(
                        label: 'Protein',
                        consumed: consumed.proteinG,
                        target: targets.proteinG.toDouble(),
                        unit: 'g',
                        color: NGColors.proteinChart,
                      ),
                      const SizedBox(height: NGSpacing.sm),
                      MacroBar(
                        label: 'Carbs',
                        consumed: consumed.carbsG,
                        target: targets.carbsG.toDouble(),
                        unit: 'g',
                        color: NGColors.carbChart,
                      ),
                      const SizedBox(height: NGSpacing.sm),
                      MacroBar(
                        label: 'Fat',
                        consumed: consumed.fatG,
                        target: targets.fatG.toDouble(),
                        unit: 'g',
                        color: NGColors.fatChart,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextMealCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planner = ref.watch(plannerControllerProvider);
    final today = Dates.dayKey(DateTime.now());
    final day = planner.plan?.dayFor(today);
    final next = day?.meals.isNotEmpty ?? false ? day!.meals.first : null;
    return NGCard(
      onTap: () => context.go('/plan'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(context, Icons.restaurant_menu_rounded, 'Next meal'),
          const SizedBox(height: NGSpacing.sm),
          if (next != null) ...[
            Text(
              next.recipeName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              '${next.totals.kcal.round()} kcal · ${next.slot.label}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else
            Text(
              'Generate a plan to see meals',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _FastingCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fasting = ref.watch(fastingControllerProvider);
    final active = fasting.active;
    return NGCard(
      onTap: () => context.push('/fasting'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(context, Icons.timer_outlined, 'Fasting'),
          const SizedBox(height: NGSpacing.sm),
          if (active != null && active.isRunning) ...[
            Text(
              Dates.formatDuration(active.elapsed(DateTime.now())),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'of ${active.targetHours}h',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else
            Text('Not fasting', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _WaterCard extends ConsumerWidget {
  const _WaterCard({required this.target});
  final int target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diary = ref.watch(diaryControllerProvider);
    return NGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(context, Icons.water_drop_outlined, 'Water'),
          const SizedBox(height: NGSpacing.sm),
          Text(
            '${diary.waterMl} / $target ml',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: NGSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () =>
                  ref.read(diaryControllerProvider.notifier).addWater(250),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: NGSpacing.md),
              ),
              child: const Text('+250 ml'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider);
    final habit = progress.habits.isNotEmpty ? progress.habits.first : null;
    final done = habit != null && progress.todayHabitIds.contains(habit.id);
    return NGCard(
      onTap: () => context.go('/progress'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(context, Icons.task_alt_rounded, 'Daily habit'),
          const SizedBox(height: NGSpacing.sm),
          if (habit != null)
            Row(
              children: [
                Checkbox(
                  value: done,
                  onChanged: (_) => ref
                      .read(progressControllerProvider.notifier)
                      .toggleHabitToday(habit.id),
                ),
                Expanded(
                  child: Text(
                    habit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            )
          else
            Text(
              'Add a small daily habit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _CoachShortcut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NGCard(
      color: theme.colorScheme.primaryContainer,
      onTap: () => context.go('/coach'),
      child: Row(
        children: [
          Icon(
            Icons.forum_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: NGSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask the AI Nutrition Coach',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'General, evidence-grounded nutrition help',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }
}

class _ProgressGlance extends ConsumerWidget {
  const _ProgressGlance({required this.hideWeight});
  final bool hideWeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hideWeight) return const SizedBox.shrink();
    final progress = ref.watch(progressControllerProvider);
    if (progress.weights.isEmpty) {
      return NGCard(
        onTap: () => context.go('/progress'),
        child: Row(
          children: [
            const Icon(Icons.insights_outlined),
            const SizedBox(width: NGSpacing.md),
            Expanded(
              child: Text(
                'Log your weight to see gentle trends over time',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    final latest = progress.weights.last;
    return NGCard(
      onTap: () => context.go('/progress'),
      child: Row(
        children: [
          _cardHeader(context, Icons.monitor_weight_outlined, 'Latest weight'),
          const Spacer(),
          Text(
            '${latest.weightKg.toStringAsFixed(1)} kg',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

Widget _cardHeader(BuildContext context, IconData icon, String label) {
  final theme = Theme.of(context);
  return Row(
    children: [
      Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
      const SizedBox(width: NGSpacing.xs),
      Text(label, style: theme.textTheme.labelMedium),
    ],
  );
}
