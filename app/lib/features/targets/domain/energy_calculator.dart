import '../../profile/domain/user_profile.dart';

/// Version identifier recorded with every calculated target so results stay
/// reproducible across app updates (master requirement §7).
const String energyCalcVersion = 'ng-energy-v1';

/// Safety floor: NutriGuide never recommends eating below this many kcal/day.
/// If a goal would require less, the target is clamped, a warning is issued,
/// and the user is advised to work with a professional instead.
/// Configurable server-side via Remote Config in production builds.
const int defaultCalorieFloor = 1200;

/// Maximum sustainable automatic deficit (fraction of TDEE). Larger deficits
/// require professional supervision and are never auto-recommended.
const double maxDeficitFraction = 0.20;
const double maxDeficitKcal = 500;
const double gainSurplusKcal = 300;

/// Weekly weight-change rate considered the safe upper bound for flagging
/// unrealistic target dates (kg per week).
const double maxSafeWeeklyLossKg = 0.75;

enum TargetWarning {
  calorieFloorApplied(
    'Your estimated goal was below our safety minimum, so we raised it to a '
    'safer level. For faster changes, please work with a registered dietitian '
    'or your physician.',
  ),
  unrealisticTargetDate(
    'Reaching your target weight by the chosen date would require losing '
    'weight faster than the generally recommended pace of about 0.25–0.75 kg '
    'per week. We suggest a later date or a smaller change.',
  ),
  professionalGuidanceAdvised(
    'Because of the health information you shared, these numbers are general '
    'estimates only. Please review any nutrition changes with your physician '
    'or a registered dietitian.',
  );

  const TargetWarning(this.message);
  final String message;
}

class NutritionTargets {
  const NutritionTargets({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.waterMl,
    required this.bmr,
    required this.tdee,
    required this.calcVersion,
    required this.methodExplanation,
    required this.warnings,
    this.userAdjusted = false,
  });

  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int fiberG;
  final int waterMl;
  final double bmr;
  final double tdee;
  final String calcVersion;

  /// Human-readable explanation of the formula, shown in the UI so the
  /// estimate is transparent (master requirement §7).
  final String methodExplanation;
  final List<TargetWarning> warnings;

  /// True when the user manually overrode the recommendation.
  final bool userAdjusted;

  NutritionTargets copyWith({
    int? calories,
    int? proteinG,
    int? carbsG,
    int? fatG,
    bool? userAdjusted,
  }) {
    return NutritionTargets(
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG,
      waterMl: waterMl,
      bmr: bmr,
      tdee: tdee,
      calcVersion: calcVersion,
      methodExplanation: methodExplanation,
      warnings: warnings,
      userAdjusted: userAdjusted ?? this.userAdjusted,
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'fiberG': fiberG,
    'waterMl': waterMl,
    'bmr': bmr,
    'tdee': tdee,
    'calcVersion': calcVersion,
    'methodExplanation': methodExplanation,
    'warnings': warnings.map((w) => w.name).toList(),
    'userAdjusted': userAdjusted,
  };

  factory NutritionTargets.fromJson(Map<String, dynamic> json) {
    return NutritionTargets(
      calories: json['calories'] as int,
      proteinG: json['proteinG'] as int,
      carbsG: json['carbsG'] as int,
      fatG: json['fatG'] as int,
      fiberG: json['fiberG'] as int,
      waterMl: json['waterMl'] as int,
      bmr: (json['bmr'] as num).toDouble(),
      tdee: (json['tdee'] as num).toDouble(),
      calcVersion: json['calcVersion'] as String,
      methodExplanation: json['methodExplanation'] as String,
      warnings: ((json['warnings'] as List?) ?? const [])
          .cast<String>()
          .map(TargetWarning.values.byName)
          .toList(),
      userAdjusted: json['userAdjusted'] as bool? ?? false,
    );
  }
}

/// Transparent calorie and macro estimation.
///
/// Basal metabolic rate uses the Mifflin–St Jeor equation (Mifflin et al.,
/// Am J Clin Nutr 1990), the equation recommended by the Academy of Nutrition
/// and Dietetics for healthy adults. When sex is unspecified the average of
/// the two equations is used and this is disclosed in the explanation.
abstract final class EnergyCalculator {
  static double mifflinStJeor({
    required double weightKg,
    required double heightCm,
    required int age,
    required BiologicalSex sex,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (sex) {
      BiologicalSex.male => base + 5,
      BiologicalSex.female => base - 161,
      BiologicalSex.unspecified => base - 78, // midpoint of +5 and −161
    };
  }

  static NutritionTargets calculate(
    UserProfile profile, {
    int calorieFloor = defaultCalorieFloor,
    DateTime? now,
  }) {
    final warnings = <TargetWarning>[];
    final bmr = mifflinStJeor(
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      age: profile.age,
      sex: profile.sex,
    );
    final tdee = bmr * profile.activityLevel.multiplier;

    double calories;
    switch (profile.goal) {
      case WellnessGoal.loseWeight:
        final deficit = _min(maxDeficitKcal, tdee * maxDeficitFraction);
        calories = tdee - deficit;
      case WellnessGoal.gainWeight:
      case WellnessGoal.buildMuscle:
        calories = tdee + gainSurplusKcal;
      case WellnessGoal.maintain:
      case WellnessGoal.improveHabits:
        calories = tdee;
    }

    if (calories < calorieFloor) {
      calories = calorieFloor.toDouble();
      warnings.add(TargetWarning.calorieFloorApplied);
    }

    if (_isTargetDateUnrealistic(profile, now: now)) {
      warnings.add(TargetWarning.unrealisticTargetDate);
    }
    if (profile.requiresProfessionalGuidance) {
      warnings.add(TargetWarning.professionalGuidanceAdvised);
    }

    // Protein per kg body weight, based on goal (within the commonly cited
    // 1.2–2.0 g/kg range for active adults; ISSN position stand 2017).
    final proteinPerKg = switch (profile.goal) {
      WellnessGoal.loseWeight => 1.8,
      WellnessGoal.buildMuscle => 1.8,
      WellnessGoal.gainWeight => 1.6,
      WellnessGoal.maintain => 1.4,
      WellnessGoal.improveHabits => 1.4,
    };
    double proteinG = profile.weightKg * proteinPerKg;
    // Protein cannot exceed 35% of calories.
    proteinG = _min(proteinG, calories * 0.35 / 4);

    // Fat at 30% of calories (within the 20–35% AMDR), carbs take the rest.
    final fatG = calories * 0.30 / 9;
    final carbsG = _max(0, (calories - proteinG * 4 - fatG * 9) / 4);

    // Fiber: 14 g per 1000 kcal (Dietary Guidelines for Americans).
    final fiberG = calories / 1000 * 14;

    // Water baseline: ~35 ml/kg bounded to a sensible range. This is general
    // guidance, not a medical prescription.
    final waterMl = (profile.weightKg * 35).clamp(1500, 4000).toDouble();

    final explanation = _explain(profile, bmr, tdee, calories, warnings);

    return NutritionTargets(
      calories: calories.round(),
      proteinG: proteinG.round(),
      carbsG: carbsG.round(),
      fatG: fatG.round(),
      fiberG: fiberG.round(),
      waterMl: waterMl.round(),
      bmr: bmr,
      tdee: tdee,
      calcVersion: energyCalcVersion,
      methodExplanation: explanation,
      warnings: warnings,
    );
  }

  static bool _isTargetDateUnrealistic(UserProfile profile, {DateTime? now}) {
    final targetWeight = profile.targetWeightKg;
    final targetDate = profile.targetDate;
    if (targetWeight == null || targetDate == null) return false;
    final deltaKg = (profile.weightKg - targetWeight).abs();
    if (deltaKg == 0) return false;
    final days = targetDate.difference(now ?? DateTime.now()).inDays;
    if (days <= 0) return true;
    final weeklyRate = deltaKg / (days / 7);
    return weeklyRate > maxSafeWeeklyLossKg;
  }

  static String _explain(
    UserProfile profile,
    double bmr,
    double tdee,
    double calories,
    List<TargetWarning> warnings,
  ) {
    final sexNote = profile.sex == BiologicalSex.unspecified
        ? ' Because sex was not specified, we use the midpoint of the male '
              'and female equations.'
        : '';
    final floorNote = warnings.contains(TargetWarning.calorieFloorApplied)
        ? ' Your target was raised to our $defaultCalorieFloor kcal safety '
              'minimum.'
        : '';
    return 'Estimated resting energy (BMR) uses the Mifflin–St Jeor equation: '
        '${bmr.round()} kcal.$sexNote Multiplied by your activity level '
        '(${profile.activityLevel.label.toLowerCase()}, '
        '×${profile.activityLevel.multiplier}) this gives an estimated daily '
        'use of ${tdee.round()} kcal. Your goal adjustment results in a '
        'target of ${calories.round()} kcal.$floorNote These are estimates — '
        'real needs vary from person to person, and you can adjust the '
        'numbers at any time.';
  }

  static double _min(double a, double b) => a < b ? a : b;
  static double _max(double a, double b) => a > b ? a : b;
}
