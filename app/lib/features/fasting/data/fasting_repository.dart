import '../../../core/storage/local_store.dart';
import '../domain/fasting_session.dart';

/// Stores the current fasting session and history. The active timer keeps
/// working offline because it is computed from stored timestamps, not a
/// running clock (master requirement §16).
class FastingRepository {
  FastingRepository(this._store);

  final LocalStore _store;
  static const String _collection = 'fasting';
  static const String _activeId = 'active';

  Future<FastingSession?> loadActive() async {
    final json = await _store.get(_collection, _activeId);
    if (json == null) return null;
    final session = FastingSession.fromJson(json);
    if (session.status == FastingStatus.completed ||
        session.status == FastingStatus.cancelled) {
      return null;
    }
    return session;
  }

  Future<void> saveActive(FastingSession session) =>
      _store.put(_collection, _activeId, session.toJson());

  Future<void> clearActive() => _store.delete(_collection, _activeId);

  Future<void> addToHistory(FastingSession session) =>
      _store.put(_collection, 'hist_${session.id}', session.toJson());

  Future<List<FastingSession>> history({int limit = 60}) async {
    final all = await _store.getAll(_collection);
    final sessions =
        all
            .where((j) => j['id'] != null)
            .map(FastingSession.fromJson)
            .where(
              (s) =>
                  s.status == FastingStatus.completed ||
                  s.status == FastingStatus.cancelled,
            )
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions.take(limit).toList();
  }
}
