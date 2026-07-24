import 'dart:math';

import '../../diets/domain/diet_catalog.dart';
import '../../profile/domain/user_profile.dart';
import 'meal_plan.dart';
import 'recipe.dart';

/// Version identifier stored on every generated plan.
const String planGeneratorVersion = 'ng-plan-v1';

/// Deterministic, rule-based meal-plan generation.
///
/// Given the user's diet, targets and constraints, selects compatible recipes
/// and scales servings so each day lands near the calorie target. Pure logic
/// with an injectable random seed, fully covered by unit tests. Generated
/// plans are re-checked by [PlanValidator] before being shown, and the
/// backend revalidates plans that sync (backend/functions/src/plan).
class PlanGenerator {
  PlanGenerator({required this.recipePool, int? seed})
    : _random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  final List<Recipe> recipePool;
  final Random _random;

  /// Serving sizes offered by the generator (quarter-serving steps keep
  /// quantities cookable — no "0.37 servings" nonsense).
  static const double minServings = 0.5;
  static const double maxServings = 3.0;

  /// Slot layout by meals-per-day preference.
  static List<MealSlot> slotsFor(int mealsPerDay) => switch (mealsPerDay) {
    <= 2 => const [MealSlot.lunch, MealSlot.dinner],
    3 => const [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner],
    4 => const [
      MealSlot.breakfast,
      MealSlot.lunch,
      MealSlot.dinner,
      MealSlot.snack,
    ],
    5 => const [
      MealSlot.breakfast,
      MealSlot.snack,
      MealSlot.lunch,
      MealSlot.dinner,
      MealSlot.snack,
    ],
    _ => const [
      MealSlot.breakfast,
      MealSlot.snack,
      MealSlot.lunch,
      MealSlot.snack,
      MealSlot.dinner,
      MealSlot.snack,
    ],
  };

  /// Calorie share for each slot in the layout, summing to 1.0.
  static List<double> calorieShares(List<MealSlot> slots) {
    final mains = slots.where((s) => s != MealSlot.snack).length;
    final snacks = slots.length - mains;
    final snackShare = snacks == 0 ? 0.0 : 0.10;
    final mainBudget = 1.0 - snackShare * snacks;
    return slots.map((s) {
      if (s == MealSlot.snack) return snackShare;
      return switch (s) {
        MealSlot.breakfast => mainBudget * 0.28,
        MealSlot.lunch => mainBudget * (mains == 2 ? 0.48 : 0.34),
        _ => mainBudget * (mains == 2 ? 0.52 : 0.38),
      };
    }).toList();
  }

  /// Recipes compatible with the profile's diet, allergies, avoid list,
  /// cooking time, budget, and explicit exclusions.
  List<Recipe> compatibleRecipes(
    UserProfile profile, {
    Set<String> excludedRecipeIds = const {},
    bool relaxLifestyle = false,
  }) {
    final diet = DietCatalog.byId(profile.dietId);
    final dietTags = diet.recipeTags.toSet();
    final allergies = profile.allergies.map((a) => a.toLowerCase()).toSet();
    final avoid = profile.avoidFoods.map((a) => a.toLowerCase()).toList();

    bool allergenSafe(Recipe r) {
      for (final allergen in r.allergens) {
        if (allergies.contains(allergen.toLowerCase())) return false;
      }
      // Free-text allergies also match ingredient and recipe names.
      for (final a in allergies) {
        if (r.name.toLowerCase().contains(a)) return false;
        if (r.ingredients.any((i) => i.name.toLowerCase().contains(a))) {
          return false;
        }
      }
      return true;
    }

    bool avoidSafe(Recipe r) {
      for (final term in avoid) {
        if (term.isEmpty) continue;
        if (r.name.toLowerCase().contains(term)) return false;
        if (r.ingredients.any((i) => i.name.toLowerCase().contains(term))) {
          return false;
        }
      }
      return true;
    }

    bool lifestyleFits(Recipe r) {
      if (relaxLifestyle) return true;
      final timeOk = switch (profile.cookingTime) {
        CookingTime.quick => r.prepMinutes <= 20,
        CookingTime.moderate => r.prepMinutes <= 45,
        CookingTime.elaborate => true,
      };
      final budgetOk = switch (profile.budget) {
        BudgetPreference.low => r.costTier <= 1,
        BudgetPreference.medium => r.costTier <= 2,
        BudgetPreference.high => true,
      };
      return timeOk && budgetOk;
    }

    return recipePool
        .where((r) => r.tags.any(dietTags.contains))
        .where(allergenSafe)
        .where(avoidSafe)
        .where((r) => !excludedRecipeIds.contains(r.id))
        .where(lifestyleFits)
        .toList();
  }

  /// Generates a plan for [dayKeys]. Throws [PlanGenerationException] when the
  /// constraints leave no usable recipes (surfaced to the user with advice to
  /// relax filters — never a fabricated plan).
  MealPlan generate({
    required UserProfile profile,
    required int calorieTarget,
    required List<String> dayKeys,
    Set<String> excludedRecipeIds = const {},
    Map<String, int> ratings = const {},
  }) {
    var pool = compatibleRecipes(profile, excludedRecipeIds: excludedRecipeIds);
    if (pool.length < 3) {
      // Relax cooking-time/budget before giving up; allergy and diet
      // restrictions are never relaxed.
      pool = compatibleRecipes(
        profile,
        excludedRecipeIds: excludedRecipeIds,
        relaxLifestyle: true,
      );
    }
    final slots = slotsFor(profile.mealsPerDay);
    for (final slot in slots.toSet()) {
      if (!pool.any((r) => r.slots.contains(slot))) {
        throw PlanGenerationException(
          'No compatible recipes for ${slot.label.toLowerCase()} with the '
          'current diet, allergy and preference filters.',
        );
      }
    }

    final days = <DayPlan>[];
    final recentIds = <String>[];
    var mealCounter = 0;

    for (final dayKey in dayKeys) {
      final shares = calorieShares(slots);
      final meals = <PlannedMeal>[];
      for (var i = 0; i < slots.length; i++) {
        final slot = slots[i];
        final slotTarget = calorieTarget * shares[i];
        final candidates = pool.where((r) => r.slots.contains(slot)).toList();
        final choice = _pick(
          candidates,
          slotTarget,
          recentIds,
          ratings,
          profile.preferredCuisines,
        );
        final servings = _bestServings(choice, slotTarget);
        meals.add(
          PlannedMeal(
            id: 'pm_${dayKey}_${mealCounter++}',
            slot: slot,
            recipeId: choice.id,
            servings: servings,
            perServing: choice.perServing,
            recipeName: choice.name,
          ),
        );
        recentIds.add(choice.id);
        if (recentIds.length > 6) recentIds.removeAt(0);
      }
      days.add(
        DayPlan(dayKey: dayKey, meals: _closeCalorieGap(meals, calorieTarget)),
      );
    }

    return MealPlan(
      id: 'plan_${dayKeys.first}_${_random.nextInt(1 << 31)}',
      dietId: profile.dietId,
      calorieTarget: calorieTarget,
      days: days,
      createdAt: DateTime.now(),
      generatorVersion: planGeneratorVersion,
    );
  }

  /// Replaces a single meal, respecting locks and reusing the same slot.
  DayPlan regenerateMeal({
    required UserProfile profile,
    required DayPlan day,
    required String mealId,
    required int calorieTarget,
    Set<String> excludedRecipeIds = const {},
  }) {
    final index = day.meals.indexWhere((m) => m.id == mealId);
    if (index < 0) return day;
    final current = day.meals[index];
    if (current.locked) return day;
    final pool = compatibleRecipes(
      profile,
      excludedRecipeIds: {...excludedRecipeIds, current.recipeId},
    ).where((r) => r.slots.contains(current.slot)).toList();
    if (pool.isEmpty) {
      throw PlanGenerationException(
        'No alternative recipes available for this slot with the current '
        'filters.',
      );
    }
    final slotKcal = current.totals.kcal;
    final choice = _pick(
      pool,
      slotKcal,
      [current.recipeId],
      const {},
      profile.preferredCuisines,
    );
    final meals = [...day.meals];
    meals[index] = current.copyWith(
      recipeId: choice.id,
      recipeName: choice.name,
      perServing: choice.perServing,
      servings: _bestServings(choice, slotKcal),
    );
    return day.copyWith(meals: meals);
  }

  Recipe _pick(
    List<Recipe> candidates,
    double slotKcal,
    List<String> recentIds,
    Map<String, int> ratings,
    List<String> preferredCuisines,
  ) {
    // Score: closeness to slot calories + variety + rating + cuisine match.
    Recipe? best;
    double bestScore = double.negativeInfinity;
    for (final r in candidates) {
      final servings = _bestServings(r, slotKcal);
      final kcal = r.perServing.kcal * servings;
      final closeness = 1 - ((kcal - slotKcal).abs() / slotKcal).clamp(0, 1);
      final variety = recentIds.contains(r.id) ? -0.6 : 0.0;
      final rating = ((ratings[r.id] ?? 3) - 3) * 0.15;
      final cuisine =
          preferredCuisines
              .map((c) => c.toLowerCase())
              .contains(r.cuisine.toLowerCase())
          ? 0.2
          : 0.0;
      final jitter = _random.nextDouble() * 0.15;
      final score = closeness + variety + rating + cuisine + jitter;
      if (score > bestScore) {
        bestScore = score;
        best = r;
      }
    }
    return best!;
  }

  double _bestServings(Recipe recipe, double targetKcal) {
    final perServing = recipe.perServing.kcal;
    if (perServing <= 0) return 1;
    final raw = targetKcal / perServing;
    final quantized = (raw * 4).round() / 4;
    return quantized.clamp(minServings, maxServings);
  }

  /// Nudges the largest unlocked meal so the day lands within tolerance.
  List<PlannedMeal> _closeCalorieGap(List<PlannedMeal> meals, int target) {
    final total = meals.fold<double>(0, (a, m) => a + m.totals.kcal);
    final gap = target - total;
    if (gap.abs() / target <= 0.08) return meals;
    final adjustableIndex = _largestAdjustable(meals);
    if (adjustableIndex < 0) return meals;
    final meal = meals[adjustableIndex];
    final desired = meal.totals.kcal + gap;
    final servings = ((desired / meal.perServing.kcal) * 4).round() / 4;
    final clamped = servings.clamp(minServings, maxServings);
    final result = [...meals];
    result[adjustableIndex] = meal.copyWith(servings: clamped);
    return result;
  }

  int _largestAdjustable(List<PlannedMeal> meals) {
    var index = -1;
    var largest = -1.0;
    for (var i = 0; i < meals.length; i++) {
      if (meals[i].locked) continue;
      final kcal = meals[i].totals.kcal;
      if (kcal > largest) {
        largest = kcal;
        index = i;
      }
    }
    return index;
  }
}

class PlanGenerationException implements Exception {
  PlanGenerationException(this.message);
  final String message;

  @override
  String toString() => message;
}
