import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/utils/dates.dart';
import '../../planner/domain/recipe.dart';
import '../../profile/application/profile_controller.dart';
import '../application/diary_controller.dart';
import '../domain/diary_entry.dart';
import '../domain/food_item.dart';
import 'food_search_sheet.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final diary = ref.watch(diaryControllerProvider);
    final notifier = ref.read(diaryControllerProvider.notifier);
    final targets = ref.watch(profileControllerProvider).targets;
    final day = Dates.parseDayKey(diary.dayKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food diary'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copy') notifier.copyFromYesterday();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'copy',
                child: Text('Copy yesterday’s meals'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _DayNav(
            day: day,
            onPrev: () => notifier.load(
              Dates.dayKey(day.subtract(const Duration(days: 1))),
            ),
            onNext: () =>
                notifier.load(Dates.dayKey(day.add(const Duration(days: 1)))),
          ),
          if (targets != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NGSpacing.lg),
              child: NGCard(
                padding: const EdgeInsets.all(NGSpacing.md),
                child: MacroBar(
                  label: 'Calories',
                  consumed: diary.totals.kcal,
                  target: targets.calories.toDouble(),
                  unit: 'kcal',
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          Expanded(
            child: diary.loading
                ? const _LogSkeleton()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      NGSpacing.lg,
                      NGSpacing.sm,
                      NGSpacing.lg,
                      NGSpacing.xxxl,
                    ),
                    children: [
                      for (final slot in MealSlot.values)
                        _SlotSection(
                          slot: slot,
                          entries: diary.forSlot(slot),
                          onAdd: () => _addFood(context, ref, slot),
                          onDelete: notifier.deleteEntry,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addFood(
    BuildContext context,
    WidgetRef ref,
    MealSlot slot,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FoodSearchSheet(slot: slot),
    );
  }
}

class _DayNav extends StatelessWidget {
  const _DayNav({
    required this.day,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime day;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isToday = Dates.isSameDay(day, DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NGSpacing.lg,
        vertical: NGSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous day',
          ),
          Text(
            Dates.friendly(day),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            onPressed: isToday ? null : onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }
}

class _SlotSection extends StatelessWidget {
  const _SlotSection({
    required this.slot,
    required this.entries,
    required this.onAdd,
    required this.onDelete,
  });

  final MealSlot slot;
  final List<DiaryEntry> entries;
  final VoidCallback onAdd;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = entries.fold<double>(0, (a, e) => a + e.nutrients.kcal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: NGSpacing.lg,
            bottom: NGSpacing.sm,
          ),
          child: Row(
            children: [
              Text(slot.label, style: theme.textTheme.titleMedium),
              const Spacer(),
              if (entries.isNotEmpty)
                Text(
                  '${total.round()} kcal',
                  style: theme.textTheme.labelMedium,
                ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: 'Add to ${slot.label}',
              ),
            ],
          ),
        ),
        if (entries.isEmpty)
          Text('Nothing logged yet', style: theme.textTheme.bodySmall)
        else
          for (final entry in entries)
            Dismissible(
              key: ValueKey(entry.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => onDelete(entry.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: NGSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: NGRadius.control,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.name),
                subtitle: Row(
                  children: [
                    Text('${entry.nutrients.kcal.round()} kcal'),
                    const SizedBox(width: NGSpacing.sm),
                    _SourceBadge(source: entry.source),
                  ],
                ),
                trailing: Text(
                  entry.grams > 0 ? '${entry.grams.round()} g' : '',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final NutritionSource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEstimate =
        source == NutritionSource.recipeEstimate ||
        source == NutritionSource.aiEstimate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isEstimate
            ? NGColors.caution.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: NGRadius.chip,
      ),
      child: Text(
        source == NutritionSource.verified ? 'Verified' : source.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isEstimate
              ? NGColors.caution
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LogSkeleton extends StatelessWidget {
  const _LogSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(NGSpacing.lg),
      children: const [
        SkeletonBox(height: 20, width: 120),
        SizedBox(height: NGSpacing.md),
        SkeletonBox(height: 48, radius: NGRadius.md),
        SizedBox(height: NGSpacing.sm),
        SkeletonBox(height: 48, radius: NGRadius.md),
        SizedBox(height: NGSpacing.xl),
        SkeletonBox(height: 20, width: 120),
        SizedBox(height: NGSpacing.md),
        SkeletonBox(height: 48, radius: NGRadius.md),
      ],
    );
  }
}
