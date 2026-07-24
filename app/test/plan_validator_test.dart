import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_ai/features/logging/domain/food_item.dart';
import 'package:nutriguide_ai/features/planner/domain/meal_plan.dart';
import 'package:nutriguide_ai/features/planner/domain/plan_validator.dart';
import 'package:nutriguide_ai/features/planner/domain/recipe.dart';
import 'package:nutriguide_ai/features/profile/domain/user_profile.dart';

UserProfile _profile({List<String> allergies = const []}) => UserProfile(
  id: 'u',
  displayName: 'T',
  isAdultConfirmed: true,
  country: 'PH',
  language: 'en',
  metricUnits: true,
  heightCm: 170,
  weightKg: 70,
  age: 30,
  sex: BiologicalSex.male,
  activityLevel: ActivityLevel.moderate,
  goal: WellnessGoal.maintain,
  dietId: 'balanced',
  allergies: allergies,
  avoidFoods: const [],
  mealsPerDay: 3,
  cookingTime: CookingTime.moderate,
  budget: BudgetPreference.medium,
  consentVersion: 'v1',
  disclaimerAcknowledgedAt: DateTime(2026),
);

Recipe _recipe(String id, {List<String> allergens = const []}) => Recipe(
  id: id,
  name: id,
  description: 'd',
  cuisine: 'General',
  slots: const [MealSlot.lunch],
  servings: 1,
  prepMinutes: 10,
  ingredients: const [RecipeIngredient(name: 'x', grams: 100)],
  steps: const ['s'],
  perServing: const Nutrients(kcal: 600, proteinG: 30, carbsG: 60, fatG: 20),
  source: NutritionSource.recipeEstimate,
  tags: const ['balanced'],
  allergens: allergens,
  groceryCategory: const {'x': 'Other'},
);

PlannedMeal _meal(
  String recipeId, {
  double servings = 1,
  Nutrients? nutrients,
}) => PlannedMeal(
  id: 'pm_$recipeId',
  slot: MealSlot.lunch,
  recipeId: recipeId,
  servings: servings,
  perServing:
      nutrients ??
      const Nutrients(kcal: 600, proteinG: 30, carbsG: 60, fatG: 20),
  recipeName: recipeId,
);

MealPlan _plan(List<PlannedMeal> meals, {int target = 1800}) => MealPlan(
  id: 'p',
  dietId: 'balanced',
  calorieTarget: target,
  days: [DayPlan(dayKey: '2026-07-21', meals: meals)],
  createdAt: DateTime(2026),
  generatorVersion: 'test',
);

void main() {
  group('PlanValidator', () {
    test('accepts a well-formed plan', () {
      final plan = _plan([_meal('a'), _meal('b'), _meal('c')]);
      final issues = PlanValidator.validate(
        plan,
        profile: _profile(),
        recipesById: {'a': _recipe('a'), 'b': _recipe('b'), 'c': _recipe('c')},
      );
      expect(PlanValidator.isAcceptable(issues), isTrue);
    });

    test('rejects impossible serving quantities', () {
      final plan = _plan([_meal('a', servings: 9)]);
      final issues = PlanValidator.validate(
        plan,
        profile: _profile(),
        recipesById: {'a': _recipe('a')},
      );
      expect(issues.any((i) => i.code == 'bad_servings' && i.blocking), isTrue);
    });

    test('rejects energy inconsistent with macros', () {
      final plan = _plan([
        _meal(
          'a',
          nutrients: const Nutrients(
            kcal: 2000,
            proteinG: 5,
            carbsG: 5,
            fatG: 5,
          ),
        ),
      ]);
      final issues = PlanValidator.validate(
        plan,
        profile: _profile(),
        recipesById: {'a': _recipe('a')},
      );
      expect(issues.any((i) => i.code == 'inconsistent_energy'), isTrue);
    });

    test('flags an allergen violation as blocking', () {
      final plan = _plan([_meal('a')]);
      final issues = PlanValidator.validate(
        plan,
        profile: _profile(allergies: ['peanut']),
        recipesById: {
          'a': _recipe('a', allergens: ['peanut']),
        },
      );
      expect(
        issues.any((i) => i.code == 'allergen_violation' && i.blocking),
        isTrue,
      );
    });

    test('calorie deviation is advisory, not blocking', () {
      // Total 600 vs target 1800 → deviation, but non-blocking.
      final plan = _plan([_meal('a')], target: 1800);
      final issues = PlanValidator.validate(
        plan,
        profile: _profile(),
        recipesById: {'a': _recipe('a')},
      );
      final deviation = issues.where((i) => i.code == 'calorie_deviation');
      expect(deviation, isNotEmpty);
      expect(deviation.first.blocking, isFalse);
      expect(PlanValidator.isAcceptable(issues), isTrue);
    });
  });

  group('GroceryListBuilder', () {
    test('aggregates ingredient amounts across the plan', () {
      final plan = _plan([_meal('a', servings: 2), _meal('a', servings: 1)]);
      final items = GroceryListBuilder.build(plan, {'a': _recipe('a')});
      expect(items.length, 1);
      // 2 servings + 1 serving * 100 g each = 300 g of "x".
      expect(items.first.grams, closeTo(300, 0.001));
    });
  });
}
