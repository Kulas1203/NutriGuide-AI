import 'package:shared_preferences/shared_preferences.dart';

import 'store_backend.dart';

/// Web backend. `dart:io` and `path_provider` are unavailable when compiling
/// to JavaScript/WASM, so collections are persisted through
/// [SharedPreferences] (backed by browser localStorage) under
/// `localstore/<collection>` keys.
class _WebStoreBackend implements StoreBackend {
  _WebStoreBackend(this._prefs);

  final SharedPreferences? _prefs;

  static String _key(String collection) => 'localstore/$collection';

  @override
  Future<String?> read(String collection) async =>
      _prefs?.getString(_key(collection));

  @override
  Future<void> write(String collection, String body) async {
    await _prefs?.setString(_key(collection), body);
  }

  @override
  Future<void> remove(String collection) async {
    await _prefs?.remove(_key(collection));
  }

  @override
  Future<void> quarantine(String collection, String body) async {
    await _prefs?.setString('${_key(collection)}.corrupt', body);
    await _prefs?.remove(_key(collection));
  }

  @override
  Future<void> wipeAll(Iterable<String> knownCollections) async {
    final prefs = _prefs;
    if (prefs == null) return;
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('localstore/')) await prefs.remove(key);
    }
  }
}

/// Factory referenced by the conditional import in store_backend.dart.
StoreBackend makeStoreBackend(SharedPreferences? prefs) =>
    _WebStoreBackend(prefs);
