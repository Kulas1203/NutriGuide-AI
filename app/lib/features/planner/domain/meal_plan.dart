import '../../logging/domain/food_item.dart';
import 'recipe.dart';

class PlannedMeal {
  const PlannedMeal({
    required this.id,
    required this.slot,
    required this.recipeId,
    required this.servings,
    required this.perServing,
    required this.recipeName,
    this.locked = false,
  });

  final String id;
  final MealSlot slot;
  final String recipeId;
  final double servings;

  /// Snapshot of the recipe's per-serving nutrition at planning time, so a
  /// later dataset update cannot silently change a plan the user already has.
  final Nutrients perServing;
  final String recipeName;
  final bool locked;

  Nutrients get totals => perServing.scale(servings);

  PlannedMeal copyWith({
    MealSlot? slot,
    String? recipeId,
    double? servings,
    Nutrients? perServing,
    String? recipeName,
    bool? locked,
  }) => PlannedMeal(
    id: id,
    slot: slot ?? this.slot,
    recipeId: recipeId ?? this.recipeId,
    servings: servings ?? this.servings,
    perServing: perServing ?? this.perServing,
    recipeName: recipeName ?? this.recipeName,
    locked: locked ?? this.locked,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slot': slot.name,
    'recipeId': recipeId,
    'servings': servings,
    'perServing': perServing.toJson(),
    'recipeName': recipeName,
    'locked': locked,
  };

  factory PlannedMeal.fromJson(Map<String, dynamic> json) => PlannedMeal(
    id: json['id'] as String,
    slot: MealSlot.values.byName(json['slot'] as String),
    recipeId: json['recipeId'] as String,
    servings: (json['servings'] as num).toDouble(),
    perServing: Nutrients.fromJson(json['perServing'] as Map<String, dynamic>),
    recipeName: json['recipeName'] as String,
    locked: json['locked'] as bool? ?? false,
  );
}

class DayPlan {
  const DayPlan({required this.dayKey, required this.meals});

  final String dayKey;
  final List<PlannedMeal> meals;

  Nutrients get totals =>
      meals.fold(Nutrients.zero, (acc, m) => acc + m.totals);

  DayPlan copyWith({List<PlannedMeal>? meals}) =>
      DayPlan(dayKey: dayKey, meals: meals ?? this.meals);

  Map<String, dynamic> toJson() => {
    'dayKey': dayKey,
    'meals': meals.map((m) => m.toJson()).toList(),
  };

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
    dayKey: json['dayKey'] as String,
    meals: ((json['meals'] as List?) ?? const [])
        .map((m) => PlannedMeal.fromJson((m as Map).cast<String, dynamic>()))
        .toList(),
  );
}

class MealPlan {
  const MealPlan({
    required this.id,
    required this.dietId,
    required this.calorieTarget,
    required this.days,
    required this.createdAt,
    required this.generatorVersion,
  });

  final String id;
  final String dietId;
  final int calorieTarget;
  final List<DayPlan> days;
  final DateTime createdAt;

  /// Version of the generation algorithm, recorded for reproducibility.
  final String generatorVersion;

  DayPlan? dayFor(String dayKey) {
    for (final d in days) {
      if (d.dayKey == dayKey) return d;
    }
    return null;
  }

  MealPlan copyWith({List<DayPlan>? days}) => MealPlan(
    id: id,
    dietId: dietId,
    calorieTarget: calorieTarget,
    days: days ?? this.days,
    createdAt: createdAt,
    generatorVersion: generatorVersion,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'dietId': dietId,
    'calorieTarget': calorieTarget,
    'days': days.map((d) => d.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'generatorVersion': generatorVersion,
  };

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
    id: json['id'] as String,
    dietId: json['dietId'] as String,
    calorieTarget: json['calorieTarget'] as int,
    days: ((json['days'] as List?) ?? const [])
        .map((d) => DayPlan.fromJson((d as Map).cast<String, dynamic>()))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    generatorVersion: json['generatorVersion'] as String,
  );
}
