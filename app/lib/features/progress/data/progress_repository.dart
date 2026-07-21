import '../../../core/storage/local_store.dart';
import '../domain/progress_models.dart';

/// Stores weight/waist entries, habits and habit completions.
class ProgressRepository {
  ProgressRepository(this._store);

  final LocalStore _store;
  static const String _weights = 'weight_entries';
  static const String _habits = 'habits';
  static const String _habitLogs = 'habit_logs';

  Future<List<WeightEntry>> weightEntries() async {
    final all = await _store.getAll(_weights);
    return all.map(WeightEntry.fromJson).toList()
      ..sort((a, b) => a.dayKey.compareTo(b.dayKey));
  }

  Future<void> upsertWeight(WeightEntry entry) =>
      _store.put(_weights, entry.id, entry.toJson());

  Future<void> deleteWeight(String id) => _store.delete(_weights, id);

  Future<List<DailyHabit>> habits() async {
    final all = await _store.getAll(_habits);
    return all.map(DailyHabit.fromJson).where((h) => !h.archived).toList();
  }

  Future<void> upsertHabit(DailyHabit habit) =>
      _store.put(_habits, habit.id, habit.toJson());

  Future<Set<String>> habitLogIdsForDay(String dayKey) async {
    final all = await _store.getAll(_habitLogs);
    return all
        .map(HabitLog.fromJson)
        .where((l) => l.dayKey == dayKey)
        .map((l) => l.habitId)
        .toSet();
  }

  Future<void> toggleHabit(String habitId, String dayKey, bool done) async {
    final log = HabitLog(habitId: habitId, dayKey: dayKey);
    if (done) {
      await _store.put(_habitLogs, log.id, log.toJson());
    } else {
      await _store.delete(_habitLogs, log.id);
    }
  }
}
