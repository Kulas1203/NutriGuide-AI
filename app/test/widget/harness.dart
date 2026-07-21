import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_ai/app/providers.dart';
import 'package:nutriguide_ai/core/design/theme.dart';
import 'package:nutriguide_ai/core/storage/local_store.dart';
import 'package:nutriguide_ai/features/profile/data/profile_repository.dart';
import 'package:nutriguide_ai/features/profile/domain/user_profile.dart';
import 'package:nutriguide_ai/features/targets/domain/energy_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds a test ProviderScope backed by an in-memory [LocalStore], so widget
/// tests exercise real repositories and controllers without disk I/O (which
/// would never resolve under the test fake-async zone). The dev stubs (auth +
/// coach) are used automatically because no Firebase/backend dart-defines are
/// set in tests.
Future<Widget> buildTestApp(
  Widget child, {
  UserProfile? seedProfile,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) async {
  final store = LocalStore.inMemory();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  if (seedProfile != null) {
    final repo = ProfileRepository(store);
    await repo.save(seedProfile);
    await repo.saveTargets(EnergyCalculator.calculate(seedProfile));
  }

  return ProviderScope(
    overrides: [
      localStoreProvider.overrideWithValue(store),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.dark ? NGTheme.dark() : NGTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: child,
      ),
    ),
  );
}

UserProfile testProfile({
  List<String> allergies = const [],
  bool aiHistoryEnabled = true,
}) {
  return UserProfile(
    id: 'test-user',
    displayName: 'Rey',
    isAdultConfirmed: true,
    country: 'PH',
    language: 'en',
    metricUnits: true,
    heightCm: 172,
    weightKg: 72,
    age: 30,
    sex: BiologicalSex.male,
    activityLevel: ActivityLevel.moderate,
    goal: WellnessGoal.maintain,
    dietId: 'balanced',
    allergies: allergies,
    avoidFoods: const [],
    mealsPerDay: 3,
    cookingTime: CookingTime.moderate,
    budget: BudgetPreference.medium,
    consentVersion: 'v1',
    disclaimerAcknowledgedAt: DateTime(2026, 7, 21),
    aiHistoryEnabled: aiHistoryEnabled,
  );
}
