import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/utils/dates.dart';
import '../data/progress_repository.dart';
import '../domain/progress_models.dart';

class ProgressState {
  const ProgressState({
    this.weights = const [],
    this.habits = const [],
    this.todayHabitIds = const {},
    this.loading = true,
  });

  final List<WeightEntry> weights;
  final List<DailyHabit> habits;
  final Set<String> todayHabitIds;
  final bool loading;

  ProgressState copyWith({
    List<WeightEntry>? weights,
    List<DailyHabit>? habits,
    Set<String>? todayHabitIds,
    bool? loading,
  }) => ProgressState(
    weights: weights ?? this.weights,
    habits: habits ?? this.habits,
    todayHabitIds: todayHabitIds ?? this.todayHabitIds,
    loading: loading ?? this.loading,
  );
}

class ProgressController extends Notifier<ProgressState> {
  late ProgressRepository _repo;
  static const _uuid = Uuid();

  @override
  ProgressState build() {
    _repo = ref.watch(progressRepositoryProvider);
    load();
    return const ProgressState();
  }

  Future<void> load() async {
    final today = Dates.dayKey(DateTime.now());
    final weights = await _repo.weightEntries();
    final habits = await _repo.habits();
    final todayIds = await _repo.habitLogIdsForDay(today);
    state = ProgressState(
      weights: weights,
      habits: habits,
      todayHabitIds: todayIds,
      loading: false,
    );
  }

  Future<void> logWeight(double kg, {double? waistCm}) async {
    final today = Dates.dayKey(DateTime.now());
    final entry = WeightEntry(
      id: _uuid.v4(),
      dayKey: today,
      weightKg: kg,
      waistCm: waistCm,
    );
    await _repo.upsertWeight(entry);
    await load();
  }

  Future<void> deleteWeight(String id) async {
    await _repo.deleteWeight(id);
    state = state.copyWith(
      weights: state.weights.where((w) => w.id != id).toList(),
    );
  }

  Future<void> addHabit(String title) async {
    final habit = DailyHabit(id: _uuid.v4(), title: title.trim());
    await _repo.upsertHabit(habit);
    state = state.copyWith(habits: [...state.habits, habit]);
  }

  Future<void> archiveHabit(String id) async {
    final habit = state.habits.firstWhere((h) => h.id == id);
    await _repo.upsertHabit(
      DailyHabit(id: habit.id, title: habit.title, archived: true),
    );
    state = state.copyWith(
      habits: state.habits.where((h) => h.id != id).toList(),
    );
  }

  Future<void> toggleHabitToday(String habitId) async {
    final today = Dates.dayKey(DateTime.now());
    final done = !state.todayHabitIds.contains(habitId);
    await _repo.toggleHabit(habitId, today, done);
    final ids = Set<String>.from(state.todayHabitIds);
    done ? ids.add(habitId) : ids.remove(habitId);
    state = state.copyWith(todayHabitIds: ids);
  }

  /// Weekly weight-change trend (kg/week), null with fewer than 3 entries.
  double? weeklyWeightTrend() =>
      Trend.weeklySlope(state.weights.map((w) => w.weightKg).toList());
}

final progressControllerProvider =
    NotifierProvider<ProgressController, ProgressState>(ProgressController.new);
