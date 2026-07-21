import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/env.dart';
import '../core/storage/local_store.dart';
import '../features/auth/data/auth_service.dart';
import '../features/coach/data/coach_repository.dart';
import '../features/coach/data/coach_service.dart';
import '../features/coach/data/dev_coach_service.dart';
import '../features/fasting/data/fasting_repository.dart';
import '../features/logging/data/diary_repository.dart';
import '../features/logging/data/food_repository.dart';
import '../features/planner/data/plan_repository.dart';
import '../features/planner/data/recipe_repository.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/progress/data/progress_repository.dart';
import '../features/settings/data/account_service.dart';
import '../features/settings/domain/entitlements.dart';

/// All local-store collections, used by export and account deletion so no
/// collection is ever missed.
const List<String> kAllCollections = [
  'profile',
  'diary_entries',
  'water_logs',
  'planner',
  'custom_foods',
  'fasting',
  'weight_entries',
  'habits',
  'habit_logs',
  'coach_history',
  'settings',
];

/// Overridden in main() after async initialization.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());

final authServiceProvider = Provider<AuthService>((ref) {
  if (AppEnvironment.hasFirebase) {
    return FirebaseRestAuthService();
  }
  // Dev builds without Firebase credentials use the guarded local stub.
  return DevLocalAuthService(ref.watch(sharedPreferencesProvider));
});

final coachServiceProvider = Provider<CoachService>((ref) {
  if (AppEnvironment.hasBackend) {
    return BackendCoachService();
  }
  return DevCoachService();
});

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FoodRepository(ref.watch(localStoreProvider)),
);

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepository(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(localStoreProvider)),
);

final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => DiaryRepository(ref.watch(localStoreProvider)),
);

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepository(ref.watch(localStoreProvider)),
);

final fastingRepositoryProvider = Provider<FastingRepository>(
  (ref) => FastingRepository(ref.watch(localStoreProvider)),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(localStoreProvider)),
);

final coachRepositoryProvider = Provider<CoachRepository>(
  (ref) => CoachRepository(
    service: ref.watch(coachServiceProvider),
    store: ref.watch(localStoreProvider),
  ),
);

final accountServiceProvider = Provider<AccountService>(
  (ref) => AccountService(
    store: ref.watch(localStoreProvider),
    auth: ref.watch(authServiceProvider),
    collections: kAllCollections,
  ),
);

/// Feature flags. In production these come from Firebase Remote Config; the
/// launch default keeps monetization off and the coach on.
final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => const FeatureFlags(),
);

final entitlementsProvider = Provider<Entitlements>(
  (ref) => Entitlements(
    tier: SubscriptionTier.free,
    flags: ref.watch(featureFlagsProvider),
  ),
);
