import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/storage/local_store.dart';
import '../domain/app_settings.dart';

class SettingsController extends Notifier<AppSettings> {
  late LocalStore _store;
  static const _collection = 'settings';
  static const _id = 'app';

  @override
  AppSettings build() {
    _store = ref.watch(localStoreProvider);
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final json = await _store.get(_collection, _id);
    if (json != null) state = AppSettings.fromJson(json);
  }

  Future<void> _persist() => _store.put(_collection, _id, state.toJson());

  Future<void> update(AppSettings settings) async {
    state = settings;
    await _persist();
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
