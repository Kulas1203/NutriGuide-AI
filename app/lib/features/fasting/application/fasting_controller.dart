import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../diets/domain/diet_program.dart';
import '../data/fasting_repository.dart';
import '../domain/fasting_session.dart';

class FastingState {
  const FastingState({
    this.active,
    this.history = const [],
    this.loading = true,
  });

  final FastingSession? active;
  final List<FastingSession> history;
  final bool loading;

  FastingState copyWith({
    FastingSession? active,
    bool clearActive = false,
    List<FastingSession>? history,
    bool? loading,
  }) => FastingState(
    active: clearActive ? null : (active ?? this.active),
    history: history ?? this.history,
    loading: loading ?? this.loading,
  );
}

class FastingController extends Notifier<FastingState> {
  late FastingRepository _repo;
  static const _uuid = Uuid();
  Timer? _ticker;

  bool _disposed = false;

  @override
  FastingState build() {
    _repo = ref.watch(fastingRepositoryProvider);
    ref.onDispose(() {
      _disposed = true;
      _ticker?.cancel();
    });
    _load();
    return const FastingState();
  }

  Future<void> _load() async {
    final active = await _repo.loadActive();
    final history = await _repo.history();
    state = FastingState(active: active, history: history, loading: false);
    if (active?.isRunning ?? false) _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    // A one-second ticker only rebuilds the timer display; the elapsed value
    // itself is derived from stored timestamps so it survives app restarts.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed) state = state.copyWith();
    });
  }

  Future<void> start(FastingSchedule schedule) async {
    final session = FastingSession(
      id: _uuid.v4(),
      scheduleId: schedule.id,
      targetHours: schedule.fastingHours,
      startedAt: DateTime.now(),
    );
    await _repo.saveActive(session);
    state = state.copyWith(active: session);
    _startTicker();
  }

  Future<void> pause() async {
    final active = state.active;
    if (active == null || active.status != FastingStatus.active) return;
    final paused = active.copyWith(
      status: FastingStatus.paused,
      pausedAt: DateTime.now(),
    );
    await _repo.saveActive(paused);
    state = state.copyWith(active: paused);
    _ticker?.cancel();
  }

  Future<void> resume() async {
    final active = state.active;
    if (active == null ||
        active.status != FastingStatus.paused ||
        active.pausedAt == null) {
      return;
    }
    final extraPause = DateTime.now().difference(active.pausedAt!);
    final resumed = active.copyWith(
      status: FastingStatus.active,
      pausedAt: null,
      accumulatedPause: active.accumulatedPause + extraPause,
    );
    await _repo.saveActive(resumed);
    state = state.copyWith(active: resumed);
    _startTicker();
  }

  /// Stops the fast immediately with no confirmation friction (master
  /// requirement §11). Completed if target reached, otherwise recorded as
  /// ended early — never framed as failure.
  Future<void> stop() async {
    final active = state.active;
    if (active == null) return;
    final now = DateTime.now();
    final reachedTarget = active.elapsed(now) >= active.target;
    final ended = active.copyWith(
      status: reachedTarget ? FastingStatus.completed : FastingStatus.cancelled,
      endedAt: now,
    );
    _ticker?.cancel();
    await _repo.addToHistory(ended);
    await _repo.clearActive();
    final history = await _repo.history();
    state = FastingState(active: null, history: history, loading: false);
  }

  Future<void> setNote(String note) async {
    final active = state.active;
    if (active == null) return;
    final updated = active.copyWith(note: note);
    await _repo.saveActive(updated);
    state = state.copyWith(active: updated);
  }
}

final fastingControllerProvider =
    NotifierProvider<FastingController, FastingState>(FastingController.new);
