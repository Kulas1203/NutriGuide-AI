import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../targets/domain/energy_calculator.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

class ProfileState {
  const ProfileState({this.profile, this.targets, this.loading = true});

  final UserProfile? profile;
  final NutritionTargets? targets;
  final bool loading;

  bool get hasProfile => profile != null;

  ProfileState copyWith({
    UserProfile? profile,
    NutritionTargets? targets,
    bool? loading,
  }) => ProfileState(
    profile: profile ?? this.profile,
    targets: targets ?? this.targets,
    loading: loading ?? this.loading,
  );
}

class ProfileController extends Notifier<ProfileState> {
  late ProfileRepository _repo;

  @override
  ProfileState build() {
    _repo = ref.watch(profileRepositoryProvider);
    _load();
    return const ProfileState();
  }

  Future<void> _load() => load();

  Future<void> load() async {
    final profile = await _repo.load();
    final targets = await _repo.loadTargets();
    state = ProfileState(profile: profile, targets: targets, loading: false);
  }

  /// Saves a profile and (re)computes targets. Used at end of onboarding and
  /// whenever profile changes that affect energy needs.
  Future<void> saveProfile(
    UserProfile profile, {
    bool recomputeTargets = true,
  }) async {
    await _repo.save(profile);
    NutritionTargets? targets = state.targets;
    if (recomputeTargets || targets == null) {
      targets = EnergyCalculator.calculate(profile);
      // Preserve a prior manual override's flag only if user hadn't changed
      // the inputs; otherwise recompute cleanly.
      await _repo.saveTargets(targets);
    }
    state = ProfileState(profile: profile, targets: targets, loading: false);
  }

  /// Applies user-adjusted targets (after explicit confirmation in the UI).
  Future<void> setTargets(NutritionTargets targets) async {
    await _repo.saveTargets(targets);
    state = state.copyWith(targets: targets);
  }

  Future<void> recompute() async {
    final profile = state.profile;
    if (profile == null) return;
    final targets = EnergyCalculator.calculate(profile);
    await _repo.saveTargets(targets);
    state = state.copyWith(targets: targets);
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);
