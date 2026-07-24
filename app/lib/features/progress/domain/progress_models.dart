/// Progress-tracking domain models.
library;

class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.dayKey,
    required this.weightKg,
    this.waistCm,
    this.note,
  });

  final String id;
  final String dayKey;
  final double weightKg;
  final double? waistCm;
  final String? note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayKey': dayKey,
    'weightKg': weightKg,
    'waistCm': waistCm,
    'note': note,
  };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    id: json['id'] as String,
    dayKey: json['dayKey'] as String,
    weightKg: (json['weightKg'] as num).toDouble(),
    waistCm: (json['waistCm'] as num?)?.toDouble(),
    note: json['note'] as String?,
  );
}

/// A small self-chosen daily habit ("vegetables with lunch", "walk after
/// dinner"). Habit language stays supportive: missing a day is never
/// penalized (no streak-loss shaming, master requirement §12).
class DailyHabit {
  const DailyHabit({
    required this.id,
    required this.title,
    this.archived = false,
  });

  final String id;
  final String title;
  final bool archived;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'archived': archived,
  };

  factory DailyHabit.fromJson(Map<String, dynamic> json) => DailyHabit(
    id: json['id'] as String,
    title: json['title'] as String,
    archived: json['archived'] as bool? ?? false,
  );
}

class HabitLog {
  const HabitLog({required this.habitId, required this.dayKey});

  final String habitId;
  final String dayKey;

  String get id => '${habitId}_$dayKey';

  Map<String, dynamic> toJson() => {'habitId': habitId, 'dayKey': dayKey};

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
    habitId: json['habitId'] as String,
    dayKey: json['dayKey'] as String,
  );
}

/// Simple linear trend over (x=day index, y=value) used to show direction
/// without over-reading daily fluctuations.
abstract final class Trend {
  /// Returns change per week, or null with fewer than 3 points.
  static double? weeklySlope(List<double> values) {
    final n = values.length;
    if (n < 3) return null;
    final xs = List.generate(n, (i) => i.toDouble());
    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = values.reduce((a, b) => a + b) / n;
    var num = 0.0;
    var den = 0.0;
    for (var i = 0; i < n; i++) {
      num += (xs[i] - meanX) * (values[i] - meanY);
      den += (xs[i] - meanX) * (xs[i] - meanX);
    }
    if (den == 0) return null;
    return num / den * 7; // per-day slope -> per-week
  }
}
