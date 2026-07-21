import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_ai/features/profile/domain/user_profile.dart';
import 'package:nutriguide_ai/features/targets/domain/energy_calculator.dart';

UserProfile _profile({
  double weightKg = 80,
  double heightCm = 180,
  int age = 30,
  BiologicalSex sex = BiologicalSex.male,
  ActivityLevel activity = ActivityLevel.moderate,
  WellnessGoal goal = WellnessGoal.maintain,
  List<HealthFlag> flags = const [],
  double? targetWeightKg,
  DateTime? targetDate,
}) {
  return UserProfile(
    id: 'u1',
    displayName: 'Test',
    isAdultConfirmed: true,
    country: 'PH',
    language: 'en',
    metricUnits: true,
    heightCm: heightCm,
    weightKg: weightKg,
    age: age,
    sex: sex,
    activityLevel: activity,
    goal: goal,
    dietId: 'balanced',
    allergies: const [],
    avoidFoods: const [],
    mealsPerDay: 3,
    cookingTime: CookingTime.moderate,
    budget: BudgetPreference.medium,
    consentVersion: 'v1',
    disclaimerAcknowledgedAt: DateTime(2026),
    healthFlags: flags,
    targetWeightKg: targetWeightKg,
    targetDate: targetDate,
  );
}

void main() {
  group('Mifflin–St Jeor BMR', () {
    test('matches the published formula for a male', () {
      // 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
      final bmr = EnergyCalculator.mifflinStJeor(
        weightKg: 80,
        heightCm: 180,
        age: 30,
        sex: BiologicalSex.male,
      );
      expect(bmr, closeTo(1780, 0.001));
    });

    test('matches the published formula for a female', () {
      // 10*60 + 6.25*165 - 5*30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
      final bmr = EnergyCalculator.mifflinStJeor(
        weightKg: 60,
        heightCm: 165,
        age: 30,
        sex: BiologicalSex.female,
      );
      expect(bmr, closeTo(1320.25, 0.001));
    });

    test('unspecified sex uses the midpoint of male and female', () {
      final male = EnergyCalculator.mifflinStJeor(
        weightKg: 70,
        heightCm: 170,
        age: 40,
        sex: BiologicalSex.male,
      );
      final female = EnergyCalculator.mifflinStJeor(
        weightKg: 70,
        heightCm: 170,
        age: 40,
        sex: BiologicalSex.female,
      );
      final unspecified = EnergyCalculator.mifflinStJeor(
        weightKg: 70,
        heightCm: 170,
        age: 40,
        sex: BiologicalSex.unspecified,
      );
      expect(unspecified, closeTo((male + female) / 2, 0.001));
    });
  });

  group('Target calculation', () {
    test('maintenance target equals TDEE', () {
      final t = EnergyCalculator.calculate(_profile());
      expect(t.calories, closeTo(t.tdee.round(), 1));
      expect(t.calcVersion, energyCalcVersion);
    });

    test('weight loss applies a bounded deficit, never below TDEE-500', () {
      final t = EnergyCalculator.calculate(
        _profile(goal: WellnessGoal.loseWeight),
      );
      final deficit = t.tdee - t.calories;
      expect(deficit, lessThanOrEqualTo(500 + 0.5));
      expect(deficit, lessThanOrEqualTo(t.tdee * maxDeficitFraction + 0.5));
    });

    test('never recommends below the calorie safety floor', () {
      // Small, older, sedentary profile with a loss goal would compute low.
      final t = EnergyCalculator.calculate(
        _profile(
          weightKg: 45,
          heightCm: 150,
          age: 70,
          sex: BiologicalSex.female,
          activity: ActivityLevel.sedentary,
          goal: WellnessGoal.loseWeight,
        ),
      );
      expect(t.calories, greaterThanOrEqualTo(defaultCalorieFloor));
      expect(t.warnings, contains(TargetWarning.calorieFloorApplied));
    });

    test('gain goal adds a surplus', () {
      final maintain = EnergyCalculator.calculate(_profile());
      final gain = EnergyCalculator.calculate(
        _profile(goal: WellnessGoal.gainWeight),
      );
      expect(gain.calories, greaterThan(maintain.calories));
    });

    test('macros are internally consistent with calories (±10%)', () {
      final t = EnergyCalculator.calculate(_profile());
      final macroKcal = t.proteinG * 4 + t.carbsG * 4 + t.fatG * 9;
      expect((macroKcal - t.calories).abs() / t.calories, lessThan(0.1));
    });

    test('protein never exceeds 35% of calories', () {
      final t = EnergyCalculator.calculate(
        _profile(weightKg: 130, goal: WellnessGoal.buildMuscle),
      );
      expect(t.proteinG * 4, lessThanOrEqualTo(t.calories * 0.35 + 4));
    });

    test('health flags add professional-guidance warning', () {
      final t = EnergyCalculator.calculate(
        _profile(flags: [HealthFlag.kidneyDisease]),
      );
      expect(t.warnings, contains(TargetWarning.professionalGuidanceAdvised));
    });

    test('unrealistic target date is flagged', () {
      final t = EnergyCalculator.calculate(
        _profile(
          goal: WellnessGoal.loseWeight,
          weightKg: 90,
          targetWeightKg: 70,
          targetDate: DateTime(2026, 1, 15),
        ),
        now: DateTime(2026, 1, 1),
      );
      // 20 kg in two weeks is far beyond the safe pace.
      expect(t.warnings, contains(TargetWarning.unrealisticTargetDate));
    });

    test('realistic target date is not flagged', () {
      final t = EnergyCalculator.calculate(
        _profile(
          goal: WellnessGoal.loseWeight,
          weightKg: 80,
          targetWeightKg: 78,
          targetDate: DateTime(2026, 3, 1),
        ),
        now: DateTime(2026, 1, 1),
      );
      expect(t.warnings, isNot(contains(TargetWarning.unrealisticTargetDate)));
    });

    test('serialization round-trips', () {
      final t = EnergyCalculator.calculate(_profile());
      final restored = NutritionTargets.fromJson(t.toJson());
      expect(restored.calories, t.calories);
      expect(restored.proteinG, t.proteinG);
      expect(restored.warnings, t.warnings);
      expect(restored.calcVersion, t.calcVersion);
    });
  });
}
