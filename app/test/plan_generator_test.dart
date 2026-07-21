import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_ai/features/logging/domain/food_item.dart';
import 'package:nutriguide_ai/features/planner/domain/meal_plan.dart';
import 'package:nutriguide_ai/features/planner/domain/plan_generator.dart';
import 'package:nutriguide_ai/features/planner/domain/plan_validator.dart';
import 'package:nutriguide_ai/features/planner/domain/recipe.dart';
import 'package:nutriguide_ai/features/profile/domain/user_profile.dart';

Recipe _recipe(
  String id, {
  required List<MealSlot> slots,
  required List<String> tags,
  List<String> allergens = const [],
  double kcal = 500,
  int prep = 20,
  int cost = 1,
}) {
  return Recipe(
    id: id,
    name: id,
    description: 'desc',
    cuisine: 'General',
    slots: slots,
    servings: 1,
    prepMinutes: prep,
    ingredients: const [RecipeIngredient(name: 'thing', grams: 100)],
    steps: const ['do it'],
    perServing: Nutrients(
      kcal: kcal,
      proteinG: kcal * 0.3 / 4,
      carbsG: kcal * 0.4 / 4,
      fatG: kcal * 0.3 / 9,
    ),
    source: NutritionSource.recipeEstimate,
    tags: tags,
    allergens: allergens,
    costTier: cost,
    groceryCategory: const {'thing': 'Other'},
  );
}

List<Recipe> _pool() => [
  for (final slot in [
    MealSlot.breakfast,
    MealSlot.lunch,
    MealSlot.dinner,
    MealSlot.snack,
  ])
    for (var i = 0; i < 4; i++)
      _recipe(
        '${slot.name}_$i',
        slots: [slot],
        tags: ['balanced', 'general'],
        kcal: 300 + i * 120,
      ),
  _recipe(
    'peanut_dish',
    slots: [MealSlot.lunch],
    tags: ['balanced'],
    allergens: ['peanut'],
  ),
  _recipe('veg_dish', slots: [MealSlot.dinner], tags: ['vegan']),
];

UserProfile _profile({
  String dietId = 'balanced',
  List<String> allergies = const [],
  int mealsPerDay = 3,
  CookingTime cooking = CookingTime.elaborate,
  BudgetPreference budget = BudgetPreference.high,
}) {
  return UserProfile(
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
    dietId: dietId,
    allergies: allergies,
    avoidFoods: const [],
    mealsPerDay: mealsPerDay,
    cookingTime: cooking,
    budget: budget,
    consentVersion: 'v1',
    disclaimerAcknowledgedAt: DateTime(2026),
  );
}

void main() {
  group('PlanGenerator', () {
    test('generates the requested number of days with correct slots', () {
      final gen = PlanGenerator(recipePool: _pool(), seed: 1);
      final plan = gen.generate(
        profile: _profile(),
        calorieTarget: 2000,
        dayKeys: ['2026-07-21', '2026-07-22'],
      );
      expect(plan.days.length, 2);
      expect(plan.generatorVersion, planGeneratorVersion);
      for (final day in plan.days) {
        expect(day.meals.map((m) => m.slot).toSet(), {
          MealSlot.breakfast,
          MealSlot.lunch,
          MealSlot.dinner,
        });
      }
    });

    test('daily totals land within tolerance of the target', () {
      final gen = PlanGenerator(recipePool: _pool(), seed: 7);
      final plan = gen.generate(
        profile: _profile(),
        calorieTarget: 2000,
        dayKeys: ['2026-07-21'],
      );
      final total = plan.days.first.totals.kcal;
      expect(
        (total - 2000).abs() / 2000,
        lessThanOrEqualTo(PlanValidator.calorieToleranceFraction),
      );
    });

    test('never selects recipes with the user\'s allergen', () {
      final gen = PlanGenerator(recipePool: _pool(), seed: 3);
      final plan = gen.generate(
        profile: _profile(allergies: ['peanut']),
        calorieTarget: 2000,
        dayKeys: ['2026-07-21', '2026-07-22', '2026-07-23'],
      );
      final ids = plan.days
          .expand((d) => d.meals)
          .map((m) => m.recipeId)
          .toSet();
      expect(ids, isNot(contains('peanut_dish')));
    });

    test('throws when constraints leave no recipes for a slot', () {
      // Vegan diet but pool has no vegan breakfast/lunch.
      final gen = PlanGenerator(
        recipePool: [
          _recipe('veg_dinner', slots: [MealSlot.dinner], tags: ['vegan']),
        ],
        seed: 1,
      );
      expect(
        () => gen.generate(
          profile: _profile(dietId: 'vegan'),
          calorieTarget: 2000,
          dayKeys: ['2026-07-21'],
        ),
        throwsA(isA<PlanGenerationException>()),
      );
    });

    test('is deterministic for a fixed seed', () {
      final a = PlanGenerator(recipePool: _pool(), seed: 42).generate(
        profile: _profile(),
        calorieTarget: 2000,
        dayKeys: ['2026-07-21'],
      );
      final b = PlanGenerator(recipePool: _pool(), seed: 42).generate(
        profile: _profile(),
        calorieTarget: 2000,
        dayKeys: ['2026-07-21'],
      );
      expect(
        a.days.first.meals.map((m) => m.recipeId).toList(),
        b.days.first.meals.map((m) => m.recipeId).toList(),
      );
    });

    test('servings stay within cookable bounds', () {
      final gen = PlanGenerator(recipePool: _pool(), seed: 9);
      final plan = gen.generate(
        profile: _profile(),
        calorieTarget: 2500,
        dayKeys: ['2026-07-21'],
      );
      for (final meal in plan.days.first.meals) {
        expect(meal.servings, greaterThanOrEqualTo(PlanGenerator.minServings));
        expect(meal.servings, lessThanOrEqualTo(PlanGenerator.maxServings));
      }
    });

    test('locked meals are not replaced on regeneration', () {
      final gen = PlanGenerator(recipePool: _pool(), seed: 5);
      final plan = gen.generate(
        profile: _profile(),
        calorieTarget: 2000,
        dayKeys: ['2026-07-21'],
      );
      var day = plan.days.first;
      final locked = day.meals.first.copyWith(locked: true);
      day = day.copyWith(meals: [locked, ...day.meals.skip(1)]);
      final result = gen.regenerateMeal(
        profile: _profile(),
        day: day,
        mealId: locked.id,
        calorieTarget: 2000,
      );
      expect(result.meals.first.recipeId, locked.recipeId);
    });
  });

  group('MealPlan serialization', () {
    test('round-trips', () {
      final gen = PlanGenerator(recipePool: _pool(), seed: 2);
      final plan = gen.generate(
        profile: _profile(),
        calorieTarget: 2000,
        dayKeys: ['2026-07-21'],
      );
      final restored = MealPlan.fromJson(plan.toJson());
      expect(restored.days.length, plan.days.length);
      expect(restored.calorieTarget, plan.calorieTarget);
      expect(
        restored.days.first.meals.first.recipeId,
        plan.days.first.meals.first.recipeId,
      );
    });
  });
}
