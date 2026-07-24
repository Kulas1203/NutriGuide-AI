import '../../../core/storage/local_store.dart';
import '../../targets/domain/energy_calculator.dart';
import '../domain/user_profile.dart';

/// Persists the user profile and derived nutrition targets. Local-first;
/// the sync layer mirrors changes to the user's Firestore document.
class ProfileRepository {
  ProfileRepository(this._store);

  final LocalStore _store;
  static const String _collection = 'profile';
  static const String _profileId = 'me';
  static const String _targetsId = 'targets';

  Future<UserProfile?> load() async {
    final json = await _store.get(_collection, _profileId);
    return json == null ? null : UserProfile.fromJson(json);
  }

  Future<void> save(UserProfile profile) =>
      _store.put(_collection, _profileId, profile.toJson());

  Future<NutritionTargets?> loadTargets() async {
    final json = await _store.get(_collection, _targetsId);
    return json == null ? null : NutritionTargets.fromJson(json);
  }

  Future<void> saveTargets(NutritionTargets targets) =>
      _store.put(_collection, _targetsId, targets.toJson());

  Future<void> clear() => _store.clearCollection(_collection);
}
