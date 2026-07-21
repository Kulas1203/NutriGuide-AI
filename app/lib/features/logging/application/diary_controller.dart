import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/utils/dates.dart';
import '../../planner/domain/recipe.dart';
import '../data/diary_repository.dart';
import '../domain/diary_entry.dart';
import '../domain/food_item.dart';

class DiaryState {
  const DiaryState({
    required this.dayKey,
    this.entries = const [],
    this.waterMl = 0,
    this.loading = true,
  });

  final String dayKey;
  final List<DiaryEntry> entries;
  final int waterMl;
  final bool loading;

  Nutrients get totals =>
      entries.fold(Nutrients.zero, (acc, e) => acc + e.nutrients);

  List<DiaryEntry> forSlot(MealSlot slot) =>
      entries.where((e) => e.slot == slot).toList();

  DiaryState copyWith({
    String? dayKey,
    List<DiaryEntry>? entries,
    int? waterMl,
    bool? loading,
  }) => DiaryState(
    dayKey: dayKey ?? this.dayKey,
    entries: entries ?? this.entries,
    waterMl: waterMl ?? this.waterMl,
    loading: loading ?? this.loading,
  );
}

class DiaryController extends Notifier<DiaryState> {
  late DiaryRepository _repo;
  static const _uuid = Uuid();

  @override
  DiaryState build() {
    _repo = ref.watch(diaryRepositoryProvider);
    final today = Dates.dayKey(DateTime.now());
    load(today);
    return DiaryState(dayKey: today);
  }

  Future<void> load(String dayKey) async {
    state = DiaryState(dayKey: dayKey, loading: true);
    final entries = await _repo.entriesForDay(dayKey);
    final water = await _repo.waterForDay(dayKey);
    state = DiaryState(
      dayKey: dayKey,
      entries: entries,
      waterMl: water,
      loading: false,
    );
  }

  Future<void> logFood({
    required FoodItem food,
    required MealSlot slot,
    required double grams,
  }) async {
    final entry = DiaryEntry(
      id: _uuid.v4(),
      dayKey: state.dayKey,
      slot: slot,
      name: food.name,
      grams: grams,
      nutrients: food.forGrams(grams),
      source: food.source,
      loggedAt: DateTime.now(),
      foodId: food.id,
    );
    await _repo.upsert(entry);
    state = state.copyWith(entries: [...state.entries, entry]);
  }

  Future<void> quickAdd({
    required String name,
    required MealSlot slot,
    required Nutrients nutrients,
  }) async {
    final entry = DiaryEntry(
      id: _uuid.v4(),
      dayKey: state.dayKey,
      slot: slot,
      name: name,
      grams: 0,
      nutrients: nutrients,
      source: NutritionSource.userEntered,
      loggedAt: DateTime.now(),
    );
    await _repo.upsert(entry);
    state = state.copyWith(entries: [...state.entries, entry]);
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    await _repo.upsert(entry);
    state = state.copyWith(
      entries: [for (final e in state.entries) e.id == entry.id ? entry : e],
    );
  }

  Future<void> deleteEntry(String id) async {
    await _repo.delete(id);
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
    );
  }

  /// Copies all of yesterday's entries into the current day.
  Future<void> copyFromYesterday() async {
    final yesterday = Dates.dayKey(
      Dates.parseDayKey(state.dayKey).subtract(const Duration(days: 1)),
    );
    final source = await _repo.entriesForDay(yesterday);
    for (final e in source) {
      final copy = DiaryEntry(
        id: _uuid.v4(),
        dayKey: state.dayKey,
        slot: e.slot,
        name: e.name,
        grams: e.grams,
        nutrients: e.nutrients,
        source: e.source,
        loggedAt: DateTime.now(),
        foodId: e.foodId,
      );
      await _repo.upsert(copy);
    }
    await load(state.dayKey);
  }

  Future<void> addWater(int ml) async {
    final total = (state.waterMl + ml).clamp(0, 20000);
    await _repo.setWater(state.dayKey, total);
    state = state.copyWith(waterMl: total);
  }
}

final diaryControllerProvider = NotifierProvider<DiaryController, DiaryState>(
  DiaryController.new,
);
