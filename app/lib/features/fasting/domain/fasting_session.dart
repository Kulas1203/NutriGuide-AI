import '../../diets/domain/diet_program.dart';

enum FastingStatus { active, paused, completed, cancelled }

/// A single fasting session. All timestamps are stored UTC and rendered in
/// local time so sessions spanning midnight or timezone changes stay correct.
class FastingSession {
  const FastingSession({
    required this.id,
    required this.scheduleId,
    required this.targetHours,
    required this.startedAt,
    this.endedAt,
    this.status = FastingStatus.active,
    this.pausedAt,
    this.accumulatedPause = Duration.zero,
    this.note,
  });

  final String id;
  final String scheduleId;
  final int targetHours;
  final DateTime startedAt;
  final DateTime? endedAt;
  final FastingStatus status;
  final DateTime? pausedAt;
  final Duration accumulatedPause;
  final String? note;

  bool get isRunning => status == FastingStatus.active;

  /// Elapsed fasting time at [now], excluding paused periods.
  Duration elapsed(DateTime now) {
    final end = endedAt ?? now;
    var total = end.difference(startedAt) - accumulatedPause;
    if (status == FastingStatus.paused && pausedAt != null) {
      total -= end.difference(pausedAt!);
    }
    return total.isNegative ? Duration.zero : total;
  }

  Duration get target => Duration(hours: targetHours);

  Duration remaining(DateTime now) {
    final r = target - elapsed(now);
    return r.isNegative ? Duration.zero : r;
  }

  double progress(DateTime now) =>
      (elapsed(now).inSeconds / target.inSeconds).clamp(0.0, 1.0);

  /// When the eating window would open if the fast runs to target.
  DateTime windowOpensAt() => startedAt.add(target).add(accumulatedPause);

  FastingSession copyWith({
    DateTime? endedAt,
    FastingStatus? status,
    Object? pausedAt = _sentinel,
    Duration? accumulatedPause,
    String? note,
  }) => FastingSession(
    id: id,
    scheduleId: scheduleId,
    targetHours: targetHours,
    startedAt: startedAt,
    endedAt: endedAt ?? this.endedAt,
    status: status ?? this.status,
    pausedAt: pausedAt == _sentinel ? this.pausedAt : pausedAt as DateTime?,
    accumulatedPause: accumulatedPause ?? this.accumulatedPause,
    note: note ?? this.note,
  );

  static const Object _sentinel = Object();

  static FastingSchedule scheduleById(String id) =>
      supportedFastingSchedules.firstWhere(
        (s) => s.id == id,
        orElse: () => supportedFastingSchedules.first,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'scheduleId': scheduleId,
    'targetHours': targetHours,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'endedAt': endedAt?.toUtc().toIso8601String(),
    'status': status.name,
    'pausedAt': pausedAt?.toUtc().toIso8601String(),
    'accumulatedPauseSec': accumulatedPause.inSeconds,
    'note': note,
  };

  factory FastingSession.fromJson(Map<String, dynamic> json) => FastingSession(
    id: json['id'] as String,
    scheduleId: json['scheduleId'] as String,
    targetHours: json['targetHours'] as int,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] == null
        ? null
        : DateTime.parse(json['endedAt'] as String),
    status: FastingStatus.values.byName(json['status'] as String),
    pausedAt: json['pausedAt'] == null
        ? null
        : DateTime.parse(json['pausedAt'] as String),
    accumulatedPause: Duration(
      seconds: json['accumulatedPauseSec'] as int? ?? 0,
    ),
    note: json['note'] as String?,
  );
}

/// Safety copy shown inside the fasting feature. Deliberately central so the
/// wording stays reviewed and consistent (docs/CONTENT_REVIEW_CHECKLIST.md).
abstract final class FastingSafety {
  static const String infoText =
      'Gentle intermittent fasting fits many healthy adults, but it is not '
      'for everyone. Skip fasting and talk to a professional first if you '
      'are pregnant or breastfeeding, have diabetes on medication, take '
      'medicines that need food, or have a history of disordered eating.';

  static const String stopNowText =
      'If you feel faint, confused, unusually weak, have chest pain or keep '
      'vomiting: stop fasting now, eat or drink something, and seek medical '
      'care. Nothing in this app should keep you fasting when your body '
      'says stop.';
}
