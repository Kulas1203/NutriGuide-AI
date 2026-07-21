import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/dates.dart';
import '../../profile/application/profile_controller.dart';
import '../data/plan_repository.dart';
import '../data/recipe_repository.dart';
import '../domain/meal_plan.dart';
import '../domain/plan_generator.dart';
import '../domain/plan_validator.dart';
import '../domain/recipe.dart';

class PlannerState {
  const PlannerState({
    this.plan,
    this.recipesById = const {},
    this.issues = const [],
    this.groceryChecks = const {},
    this.prefs,
    this.loading = true,
    this.error,
  });

  final MealPlan? plan;
  final Map<String, Recipe> recipesById;
  final List<PlanIssue> issues;
  final Map<String, bool> groceryChecks;
  final PlannerPrefs? prefs;
  final bool loading;
  final String? error;

  List<PlanIssue> get advisories => issues.where((i) => !i.blocking).toList();

  PlannerState copyWith({
    MealPlan? plan,
    Map<String, Recipe>? recipesById,
    List<PlanIssue>? issues,
    Map<String, bool>? groceryChecks,
    PlannerPrefs? prefs,
    bool? loading,
    Object? error = _sentinel,
  }) => PlannerState(
    plan: plan ?? this.plan,
    recipesById: recipesById ?? this.recipesById,
    issues: issues ?? this.issues,
    groceryChecks: groceryChecks ?? this.groceryChecks,
    prefs: prefs ?? this.prefs,
    loading: loading ?? this.loading,
    error: error == _sentinel ? this.error : error as String?,
  );

  static const Object _sentinel = Object();
}

class PlannerController extends Notifier<PlannerState> {
  late PlanRepository _planRepo;
  late RecipeRepository _recipeRepo;

  @override
  PlannerState build() {
    _planRepo = ref.watch(planRepositoryProvider);
    _recipeRepo = ref.watch(recipeRepositoryProvider);
    _load();
    return const PlannerState();
  }

  Future<void> _load() async {
    final recipesById = await _recipeRepo.byIdMap();
    final plan = await _planRepo.loadActivePlan();
    final checks = await _planRepo.loadGroceryChecks();
    final prefs = await _planRepo.loadPrefs();
    List<PlanIssue> issues = const [];
    final profile = ref.read(profileControllerProvider).profile;
    if (plan != null && profile != null) {
      issues = PlanValidator.validate(
        plan,
        profile: profile,
        recipesById: recipesById,
      );
    }
    state = PlannerState(
      plan: plan,
      recipesById: recipesById,
      issues: issues,
      groceryChecks: checks,
      prefs: prefs,
      loading: false,
    );
  }

  PlanGenerator _generator() =>
      PlanGenerator(recipePool: state.recipesById.values.toList());

  /// Generates a 7-day plan. Throws [PlanGenerationException] on infeasible
  /// constraints (surfaced to the UI, never a fabricated plan).
  Future<void> generateWeek({int? seed}) async {
    final profileState = ref.read(profileControllerProvider);
    final profile = profileState.profile;
    final targets = profileState.targets;
    if (profile == null || targets == null) {
      state = state.copyWith(error: 'Complete your profile first.');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final generator = PlanGenerator(
        recipePool: state.recipesById.values.toList(),
        seed: seed,
      );
      final dayKeys = Dates.lastDays(
        DateTime.now().add(const Duration(days: 6)),
        7,
      );
      final plan = generator.generate(
        profile: profile,
        calorieTarget: targets.calories,
        dayKeys: dayKeys,
        excludedRecipeIds: state.prefs?.excluded ?? const {},
        ratings: state.prefs?.ratings ?? const {},
      );
      final issues = PlanValidator.validate(
        plan,
        profile: profile,
        recipesById: state.recipesById,
      );
      if (!PlanValidator.isAcceptable(issues)) {
        // Blocking issue: do not show an invalid plan.
        state = state.copyWith(
          loading: false,
          error:
              'The generated plan did not pass validation. Please adjust your '
              'filters and try again.',
        );
        return;
      }
      await _planRepo.saveActivePlan(plan);
      // Reset grocery checks for the new plan.
      await _planRepo.saveGroceryChecks({});
      state = state.copyWith(
        plan: plan,
        issues: issues,
        groceryChecks: {},
        loading: false,
        error: null,
      );
    } on PlanGenerationException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> regenerateMeal(String dayKey, String mealId) async {
    final plan = state.plan;
    final profile = ref.read(profileControllerProvider).profile;
    if (plan == null || profile == null) return;
    final day = plan.dayFor(dayKey);
    if (day == null) return;
    try {
      final newDay = _generator().regenerateMeal(
        profile: profile,
        day: day,
        mealId: mealId,
        calorieTarget: plan.calorieTarget,
        excludedRecipeIds: state.prefs?.excluded ?? const {},
      );
      await _saveDay(plan, newDay);
    } on PlanGenerationException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> toggleLock(String dayKey, String mealId) async {
    final plan = state.plan;
    if (plan == null) return;
    final day = plan.dayFor(dayKey);
    if (day == null) return;
    final meals = [
      for (final m in day.meals)
        m.id == mealId ? m.copyWith(locked: !m.locked) : m,
    ];
    await _saveDay(plan, day.copyWith(meals: meals));
  }

  Future<void> setServings(
    String dayKey,
    String mealId,
    double servings,
  ) async {
    final plan = state.plan;
    if (plan == null) return;
    final day = plan.dayFor(dayKey);
    if (day == null) return;
    final meals = [
      for (final m in day.meals)
        m.id == mealId
            ? m.copyWith(
                servings: servings.clamp(
                  PlanGenerator.minServings,
                  PlanGenerator.maxServings,
                ),
              )
            : m,
    ];
    await _saveDay(plan, day.copyWith(meals: meals));
  }

  Future<void> _saveDay(MealPlan plan, DayPlan newDay) async {
    final days = [
      for (final d in plan.days) d.dayKey == newDay.dayKey ? newDay : d,
    ];
    final updated = plan.copyWith(days: days);
    final profile = ref.read(profileControllerProvider).profile;
    final issues = profile == null
        ? state.issues
        : PlanValidator.validate(
            updated,
            profile: profile,
            recipesById: state.recipesById,
          );
    await _planRepo.saveActivePlan(updated);
    state = state.copyWith(plan: updated, issues: issues);
  }

  List<GroceryItem> groceryList() {
    final plan = state.plan;
    if (plan == null) return [];
    final items = GroceryListBuilder.build(plan, state.recipesById);
    return [
      for (final item in items)
        item.copyWith(checked: state.groceryChecks[item.name] ?? false),
    ];
  }

  Future<void> toggleGrocery(String name) async {
    final checks = Map<String, bool>.from(state.groceryChecks);
    checks[name] = !(checks[name] ?? false);
    await _planRepo.saveGroceryChecks(checks);
    state = state.copyWith(groceryChecks: checks);
  }

  Future<void> rateMeal(String recipeId, int rating) async {
    final prefs = state.prefs ?? PlannerPrefs();
    final ratings = Map<String, int>.from(prefs.ratings)..[recipeId] = rating;
    final updated = prefs.copyWith(ratings: ratings);
    await _planRepo.savePrefs(updated);
    state = state.copyWith(prefs: updated);
  }

  Future<void> toggleSaved(String recipeId) async {
    final prefs = state.prefs ?? PlannerPrefs();
    final saved = Set<String>.from(prefs.saved);
    saved.contains(recipeId) ? saved.remove(recipeId) : saved.add(recipeId);
    final updated = prefs.copyWith(saved: saved);
    await _planRepo.savePrefs(updated);
    state = state.copyWith(prefs: updated);
  }

  Future<void> excludeRecipe(String recipeId) async {
    final prefs = state.prefs ?? PlannerPrefs();
    final excluded = Set<String>.from(prefs.excluded)..add(recipeId);
    final updated = prefs.copyWith(excluded: excluded);
    await _planRepo.savePrefs(updated);
    state = state.copyWith(prefs: updated);
  }
}

final plannerControllerProvider =
    NotifierProvider<PlannerController, PlannerState>(PlannerController.new);
