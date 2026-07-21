import '../../planner/domain/recipe.dart';
import 'food_item.dart';

/// A logged food-diary entry. Nutrition is snapshotted at logging time so
/// later database updates never rewrite history.
class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.dayKey,
    required this.slot,
    required this.name,
    required this.grams,
    required this.nutrients,
    required this.source,
    required this.loggedAt,
    this.foodId,
    this.note,
    this.pendingSync = true,
  });

  final String id;
  final String dayKey;
  final MealSlot slot;
  final String name;
  final double grams;
  final Nutrients nutrients;
  final NutritionSource source;
  final DateTime loggedAt;
  final String? foodId;
  final String? note;

  /// True until the sync layer has confirmed the entry server-side.
  final bool pendingSync;

  DiaryEntry copyWith({
    MealSlot? slot,
    double? grams,
    Nutrients? nutrients,
    String? note,
    bool? pendingSync,
  }) => DiaryEntry(
    id: id,
    dayKey: dayKey,
    slot: slot ?? this.slot,
    name: name,
    grams: grams ?? this.grams,
    nutrients: nutrients ?? this.nutrients,
    source: source,
    loggedAt: loggedAt,
    foodId: foodId,
    note: note ?? this.note,
    pendingSync: pendingSync ?? this.pendingSync,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayKey': dayKey,
    'slot': slot.name,
    'name': name,
    'grams': grams,
    'nutrients': nutrients.toJson(),
    'source': source.name,
    'loggedAt': loggedAt.toIso8601String(),
    'foodId': foodId,
    'note': note,
    'pendingSync': pendingSync,
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'] as String,
    dayKey: json['dayKey'] as String,
    slot: MealSlot.values.byName(json['slot'] as String),
    name: json['name'] as String,
    grams: (json['grams'] as num).toDouble(),
    nutrients: Nutrients.fromJson(json['nutrients'] as Map<String, dynamic>),
    source: NutritionSource.values.byName(json['source'] as String),
    loggedAt: DateTime.parse(json['loggedAt'] as String),
    foodId: json['foodId'] as String?,
    note: json['note'] as String?,
    pendingSync: json['pendingSync'] as bool? ?? false,
  );
}

/// Daily water intake, tracked in milliliters.
class WaterLog {
  const WaterLog({required this.dayKey, required this.totalMl});

  final String dayKey;
  final int totalMl;

  Map<String, dynamic> toJson() => {'dayKey': dayKey, 'totalMl': totalMl};

  factory WaterLog.fromJson(Map<String, dynamic> json) => WaterLog(
    dayKey: json['dayKey'] as String,
    totalMl: json['totalMl'] as int,
  );
}
