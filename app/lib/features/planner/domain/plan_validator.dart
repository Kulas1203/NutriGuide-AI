import '../../profile/domain/user_profile.dart';
import 'meal_plan.dart';
import 'plan_generator.dart';
import 'recipe.dart';

/// Validation issues found in a generated plan. `blocking` issues prevent the
/// plan from being shown; advisory issues surface as notices.
class PlanIssue {
  const PlanIssue(this.code, this.message, {this.blocking = true});

  final String code;
  final String message;
  final bool blocking;

  @override
  String toString() => '$code: $message';
}

/// Server-mirrored validation of generated meal plans (the backend runs the
/// same checks in backend/functions/src/plan/validatePlan.ts before
/// accepting a synced plan).
abstract final class PlanValidator {
  /// Acceptable band around the calorie target for a full day.
  static const double calorieToleranceFraction = 0.20;

  static List<PlanIssue> validate(
    MealPlan plan, {
    required UserProfile profile,
    required Map<String, Recipe> recipesById,
  }) {
    final issues = <PlanIssue>[];
    if (plan.days.isEmpty) {
      issues.add(const PlanIssue('empty_plan', 'Plan contains no days.'));
      return issues;
    }
    final allergies = profile.allergies.map((a) => a.toLowerCase()).toSet();

    for (final day in plan.days) {
      if (day.meals.isEmpty) {
        issues.add(PlanIssue('empty_day', 'Day ${day.dayKey} has no meals.'));
        continue;
      }
      for (final meal in day.meals) {
        if (meal.servings < PlanGenerator.minServings ||
            meal.servings > PlanGenerator.maxServings) {
          issues.add(
            PlanIssue(
              'bad_servings',
              '${meal.recipeName}: impossible serving quantity '
                  '(${meal.servings}).',
            ),
          );
        }
        if (meal.perServing.kcal <= 0 ||
            meal.perServing.proteinG < 0 ||
            meal.perServing.carbsG < 0 ||
            meal.perServing.fatG < 0) {
          issues.add(
            PlanIssue(
              'bad_nutrition',
              '${meal.recipeName}: invalid nutrition values.',
            ),
          );
        }
        // Energy consistency: kcal must match macros within tolerance.
        final atwater = meal.perServing.atwaterKcal;
        if (atwater > 0 &&
            (meal.perServing.kcal - atwater).abs() / atwater > 0.25) {
          issues.add(
            PlanIssue(
              'inconsistent_energy',
              '${meal.recipeName}: calories do not match macronutrients.',
            ),
          );
        }
        final recipe = recipesById[meal.recipeId];
        if (recipe == null) {
          issues.add(
            PlanIssue(
              'unknown_recipe',
              '${meal.recipeName}: recipe ${meal.recipeId} not found.',
            ),
          );
        } else {
          for (final allergen in recipe.allergens) {
            if (allergies.contains(allergen.toLowerCase())) {
              issues.add(
                PlanIssue(
                  'allergen_violation',
                  '${meal.recipeName} contains $allergen, which is in your '
                      'allergy list.',
                ),
              );
            }
          }
        }
      }
      final total = day.totals.kcal;
      final deviation = (total - plan.calorieTarget).abs() / plan.calorieTarget;
      if (deviation > calorieToleranceFraction) {
        issues.add(
          PlanIssue(
            'calorie_deviation',
            'Day ${day.dayKey} totals ${total.round()} kcal, more than '
                '${(calorieToleranceFraction * 100).round()}% away from the '
                '${plan.calorieTarget} kcal target.',
            blocking: false,
          ),
        );
      }
    }
    return issues;
  }

  static bool isAcceptable(List<PlanIssue> issues) =>
      issues.every((i) => !i.blocking);
}

/// Builds a consolidated grocery list from a plan.
class GroceryItem {
  const GroceryItem({
    required this.name,
    required this.grams,
    required this.category,
    this.checked = false,
  });

  final String name;
  final double grams;
  final String category;
  final bool checked;

  GroceryItem copyWith({bool? checked}) => GroceryItem(
    name: name,
    grams: grams,
    category: category,
    checked: checked ?? this.checked,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'grams': grams,
    'category': category,
    'checked': checked,
  };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
    name: json['name'] as String,
    grams: (json['grams'] as num).toDouble(),
    category: json['category'] as String,
    checked: json['checked'] as bool? ?? false,
  );
}

abstract final class GroceryListBuilder {
  static List<GroceryItem> build(
    MealPlan plan,
    Map<String, Recipe> recipesById,
  ) {
    final amounts = <String, double>{};
    final categories = <String, String>{};
    for (final day in plan.days) {
      for (final meal in day.meals) {
        final recipe = recipesById[meal.recipeId];
        if (recipe == null) continue;
        final perServingFactor = meal.servings / recipe.servings;
        for (final ingredient in recipe.ingredients) {
          amounts[ingredient.name] =
              (amounts[ingredient.name] ?? 0) +
              ingredient.grams * perServingFactor;
          categories[ingredient.name] =
              recipe.groceryCategory[ingredient.name] ?? 'Other';
        }
      }
    }
    final items =
        amounts.entries
            .map(
              (e) => GroceryItem(
                name: e.key,
                grams: e.value,
                category: categories[e.key] ?? 'Other',
              ),
            )
            .toList()
          ..sort((a, b) {
            final c = a.category.compareTo(b.category);
            return c != 0 ? c : a.name.compareTo(b.name);
          });
    return items;
  }
}
