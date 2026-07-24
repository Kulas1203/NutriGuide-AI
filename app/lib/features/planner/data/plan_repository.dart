import '../../../core/storage/local_store.dart';
import '../domain/meal_plan.dart';

/// Planner preferences: saved recipes, excluded recipes, meal ratings.
class PlannerPrefs {
  PlannerPrefs({
    Set<String>? saved,
    Set<String>? excluded,
    Map<String, int>? ratings,
  }) : saved = saved ?? {},
       excluded = excluded ?? {},
       ratings = ratings ?? {};

  final Set<String> saved;
  final Set<String> excluded;
  final Map<String, int> ratings;

  PlannerPrefs copyWith({
    Set<String>? saved,
    Set<String>? excluded,
    Map<String, int>? ratings,
  }) => PlannerPrefs(
    saved: saved ?? this.saved,
    excluded: excluded ?? this.excluded,
    ratings: ratings ?? this.ratings,
  );

  Map<String, dynamic> toJson() => {
    'saved': saved.toList(),
    'excluded': excluded.toList(),
    'ratings': ratings,
  };

  factory PlannerPrefs.fromJson(Map<String, dynamic> json) => PlannerPrefs(
    saved: ((json['saved'] as List?) ?? const []).cast<String>().toSet(),
    excluded: ((json['excluded'] as List?) ?? const []).cast<String>().toSet(),
    ratings: ((json['ratings'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k as String, v as int),
    ),
  );
}

/// Persists the active meal plan, grocery-list check state, saved recipe ids,
/// meal ratings and excluded recipes.
class PlanRepository {
  PlanRepository(this._store);

  final LocalStore _store;
  static const String _collection = 'planner';
  static const String _activePlanId = 'active_plan';
  static const String _groceryId = 'grocery_state';
  static const String _prefsId = 'planner_prefs';

  Future<MealPlan?> loadActivePlan() async {
    final json = await _store.get(_collection, _activePlanId);
    return json == null ? null : MealPlan.fromJson(json);
  }

  Future<void> saveActivePlan(MealPlan plan) =>
      _store.put(_collection, _activePlanId, plan.toJson());

  Future<Map<String, bool>> loadGroceryChecks() async {
    final json = await _store.get(_collection, _groceryId);
    if (json == null) return {};
    return (json['checked'] as Map?)?.cast<String, bool>() ?? {};
  }

  Future<void> saveGroceryChecks(Map<String, bool> checks) =>
      _store.put(_collection, _groceryId, {'checked': checks});

  Future<PlannerPrefs> loadPrefs() async {
    final json = await _store.get(_collection, _prefsId);
    return PlannerPrefs.fromJson(json ?? {});
  }

  Future<void> savePrefs(PlannerPrefs prefs) =>
      _store.put(_collection, _prefsId, prefs.toJson());

  Future<void> clear() => _store.clearCollection(_collection);
}
