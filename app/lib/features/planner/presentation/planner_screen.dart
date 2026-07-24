import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/utils/dates.dart';
import '../application/planner_controller.dart';
import '../domain/meal_plan.dart';
import '../domain/recipe.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerControllerProvider);
    final notifier = ref.read(plannerControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal plan'),
        actions: [
          if (state.plan != null)
            IconButton(
              onPressed: () => context.push('/grocery'),
              icon: const Icon(Icons.shopping_cart_outlined),
              tooltip: 'Grocery list',
            ),
        ],
      ),
      floatingActionButton: state.plan == null
          ? null
          : FloatingActionButton.extended(
              onPressed: state.loading ? null : () => notifier.generateWeek(),
              icon: const Icon(Icons.autorenew_rounded),
              label: const Text('New week'),
            ),
      body: _body(context, ref, state, notifier),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    PlannerState state,
    PlannerController notifier,
  ) {
    if (state.loading && state.plan == null) {
      return const _PlannerSkeleton();
    }
    if (state.error != null && state.plan == null) {
      return ErrorState(
        message: state.error!,
        retryLabel: 'Generate plan',
        onRetry: () => notifier.generateWeek(),
      );
    }
    if (state.plan == null) {
      return EmptyState(
        icon: Icons.restaurant_menu_outlined,
        title: 'No meal plan yet',
        message:
            'Generate a personalized 7-day plan from your diet, targets and '
            'preferences.',
        actionLabel: 'Generate my plan',
        onAction: () => notifier.generateWeek(),
      );
    }
    return _PlanView(plan: state.plan!, state: state, notifier: notifier);
  }
}

class _PlanView extends StatefulWidget {
  const _PlanView({
    required this.plan,
    required this.state,
    required this.notifier,
  });

  final MealPlan plan;
  final PlannerState state;
  final PlannerController notifier;

  @override
  State<_PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<_PlanView> {
  int _dayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = widget.plan.days;
    if (_dayIndex >= days.length) _dayIndex = 0;
    final day = days[_dayIndex];

    return Column(
      children: [
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: NGSpacing.lg),
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: NGSpacing.sm),
            itemBuilder: (context, i) {
              final selected = i == _dayIndex;
              final d = Dates.parseDayKey(days[i].dayKey);
              return GestureDetector(
                onTap: () => setState(() => _dayIndex = i),
                child: Container(
                  width: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: NGRadius.control,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weekday(d.weekday),
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      Text('${d.day}', style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.state.advisories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NGSpacing.lg),
            child: NoticeBanner(
              severity: NoticeSeverity.info,
              message: widget.state.advisories.first.message,
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              NGSpacing.lg,
              NGSpacing.md,
              NGSpacing.lg,
              NGSpacing.xxxl,
            ),
            children: [
              _DayTotals(day: day, target: widget.plan.calorieTarget),
              const SizedBox(height: NGSpacing.md),
              for (final meal in day.meals)
                Padding(
                  padding: const EdgeInsets.only(bottom: NGSpacing.md),
                  child: _MealCard(
                    meal: meal,
                    recipe: widget.state.recipesById[meal.recipeId],
                    onRegenerate: () =>
                        widget.notifier.regenerateMeal(day.dayKey, meal.id),
                    onToggleLock: () =>
                        widget.notifier.toggleLock(day.dayKey, meal.id),
                    onServings: (v) =>
                        widget.notifier.setServings(day.dayKey, meal.id, v),
                    onRate: (r) => widget.notifier.rateMeal(meal.recipeId, r),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _weekday(int w) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
}

class _DayTotals extends StatelessWidget {
  const _DayTotals({required this.day, required this.target});
  final DayPlan day;
  final int target;

  @override
  Widget build(BuildContext context) {
    final totals = day.totals;
    return NGCard(
      padding: const EdgeInsets.all(NGSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: MacroBar(
              label: 'Calories',
              consumed: totals.kcal,
              target: target.toDouble(),
              unit: 'kcal',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.recipe,
    required this.onRegenerate,
    required this.onToggleLock,
    required this.onServings,
    required this.onRate,
  });

  final PlannedMeal meal;
  final Recipe? recipe;
  final VoidCallback onRegenerate;
  final VoidCallback onToggleLock;
  final ValueChanged<double> onServings;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = meal.totals;
    return NGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: NGSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: NGRadius.chip,
                ),
                child: Text(
                  meal.slot.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onToggleLock,
                icon: Icon(
                  meal.locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                ),
                tooltip: meal.locked ? 'Unlock' : 'Lock this meal',
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: meal.locked ? null : onRegenerate,
                icon: const Icon(Icons.autorenew_rounded),
                tooltip: 'Swap meal',
              ),
            ],
          ),
          const SizedBox(height: NGSpacing.xs),
          Text(meal.recipeName, style: theme.textTheme.titleMedium),
          const SizedBox(height: NGSpacing.xs),
          Text(
            '${totals.kcal.round()} kcal · P ${totals.proteinG.round()}g · '
            'C ${totals.carbsG.round()}g · F ${totals.fatG.round()}g',
            style: theme.textTheme.bodySmall,
          ),
          if (recipe != null) ...[
            const SizedBox(height: NGSpacing.xs),
            Text(
              '${recipe!.prepMinutes} min · ${recipe!.cuisine}',
              style: theme.textTheme.bodySmall,
            ),
            if (recipe!.isEstimate)
              Padding(
                padding: const EdgeInsets.only(top: NGSpacing.xs),
                child: Text(
                  'Recipe estimate',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: NGColors.caution,
                  ),
                ),
              ),
          ],
          const SizedBox(height: NGSpacing.sm),
          Row(
            children: [
              Text('Servings', style: theme.textTheme.labelMedium),
              Expanded(
                child: Slider(
                  value: meal.servings,
                  min: 0.5,
                  max: 3,
                  divisions: 10,
                  label: meal.servings.toStringAsFixed(2),
                  onChanged: onServings,
                ),
              ),
              Text(
                meal.servings.toStringAsFixed(2),
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          if (recipe != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _showRecipe(context, recipe!),
                child: const Text('View recipe'),
              ),
            ),
        ],
      ),
    );
  }

  void _showRecipe(BuildContext context, Recipe recipe) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, controller) => _RecipeSheet(
          recipe: recipe,
          controller: controller,
          onRate: onRate,
        ),
      ),
    );
  }
}

class _RecipeSheet extends StatelessWidget {
  const _RecipeSheet({
    required this.recipe,
    required this.controller,
    required this.onRate,
  });

  final Recipe recipe;
  final ScrollController controller;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(NGSpacing.lg),
      children: [
        Text(recipe.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: NGSpacing.xs),
        Text(recipe.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: NGSpacing.md),
        Wrap(
          spacing: NGSpacing.sm,
          children: [
            for (final tag in [
              '${recipe.prepMinutes} min',
              recipe.cuisine,
              '${recipe.perServing.kcal.round()} kcal/serving',
            ])
              Chip(label: Text(tag)),
          ],
        ),
        if (recipe.allergens.isNotEmpty) ...[
          const SizedBox(height: NGSpacing.sm),
          NoticeBanner(
            severity: NoticeSeverity.caution,
            message: 'Contains: ${recipe.allergens.join(', ')}',
          ),
        ],
        const SizedBox(height: NGSpacing.lg),
        Text('Ingredients', style: theme.textTheme.titleMedium),
        const SizedBox(height: NGSpacing.sm),
        for (final ing in recipe.ingredients)
          Padding(
            padding: const EdgeInsets.only(bottom: NGSpacing.xs),
            child: Row(
              children: [
                const Text('•  '),
                Expanded(child: Text(ing.name)),
                Text(
                  '${ing.grams.round()} g',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        const SizedBox(height: NGSpacing.lg),
        Text('Method', style: theme.textTheme.titleMedium),
        const SizedBox(height: NGSpacing.sm),
        for (var i = 0; i < recipe.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: NGSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}.  ', style: theme.textTheme.titleSmall),
                Expanded(child: Text(recipe.steps[i])),
              ],
            ),
          ),
        if (recipe.assumptions != null) ...[
          const SizedBox(height: NGSpacing.md),
          SourceCard(
            title: 'Estimate assumptions',
            source: recipe.assumptions!,
          ),
        ],
        const SizedBox(height: NGSpacing.md),
        SourceCard(
          title: 'Nutrition data source',
          source: recipe.source.description,
          date: recipe.sourceRef,
        ),
        const SizedBox(height: NGSpacing.lg),
        Text('Rate this meal', style: theme.textTheme.titleSmall),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                onPressed: () {
                  onRate(i);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thanks — we’ll use this to tune plans.'),
                    ),
                  );
                },
                icon: const Icon(Icons.star_border_rounded),
              ),
          ],
        ),
        const SizedBox(height: NGSpacing.xl),
      ],
    );
  }
}

class _PlannerSkeleton extends StatelessWidget {
  const _PlannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(NGSpacing.lg),
      children: const [
        SkeletonBox(height: 60, radius: NGRadius.lg),
        SizedBox(height: NGSpacing.lg),
        SkeletonBox(height: 140, radius: NGRadius.lg),
        SizedBox(height: NGSpacing.md),
        SkeletonBox(height: 140, radius: NGRadius.lg),
        SizedBox(height: NGSpacing.md),
        SkeletonBox(height: 140, radius: NGRadius.lg),
      ],
    );
  }
}
