import '../../../core/storage/local_store.dart';
import '../domain/diary_entry.dart';

/// Food diary and water storage. Entries are local-first and queued for sync;
/// the sync layer deduplicates by entry id to prevent double-logging when
/// connectivity returns (master requirement §16).
class DiaryRepository {
  DiaryRepository(this._store);

  final LocalStore _store;
  static const String _entries = 'diary_entries';
  static const String _water = 'water_logs';

  Future<List<DiaryEntry>> entriesForDay(String dayKey) async {
    final all = await _store.getAll(_entries);
    return all
        .map(DiaryEntry.fromJson)
        .where((e) => e.dayKey == dayKey)
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  Future<List<DiaryEntry>> allEntries() async {
    final all = await _store.getAll(_entries);
    return all.map(DiaryEntry.fromJson).toList();
  }

  Future<void> upsert(DiaryEntry entry) =>
      _store.put(_entries, entry.id, entry.toJson());

  Future<void> delete(String id) => _store.delete(_entries, id);

  /// Recently logged foods (by foodId) for quick re-adding, most recent first.
  Future<List<DiaryEntry>> recent({int limit = 20}) async {
    final all = (await allEntries())
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    final seen = <String>{};
    final result = <DiaryEntry>[];
    for (final e in all) {
      final key = e.foodId ?? e.name;
      if (seen.add(key)) result.add(e);
      if (result.length >= limit) break;
    }
    return result;
  }

  Future<int> waterForDay(String dayKey) async {
    final json = await _store.get(_water, dayKey);
    return json == null ? 0 : WaterLog.fromJson(json).totalMl;
  }

  Future<void> setWater(String dayKey, int totalMl) => _store.put(
    _water,
    dayKey,
    WaterLog(dayKey: dayKey, totalMl: totalMl.clamp(0, 20000)).toJson(),
  );
}
