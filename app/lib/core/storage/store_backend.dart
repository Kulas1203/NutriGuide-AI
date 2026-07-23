import 'package:shared_preferences/shared_preferences.dart';

import 'store_backend_web.dart'
    if (dart.library.io) 'store_backend_io.dart';

/// Raw, collection-level persistence for [LocalStore]. Each collection is
/// stored as a single JSON string. The concrete implementation is chosen at
/// compile time: files on Android/iOS ([dart:io]), SharedPreferences
/// (browser localStorage) on the web — so `dart:io` never reaches the web
/// build.
abstract class StoreBackend {
  /// The stored JSON body for [collection], or null if none exists.
  Future<String?> read(String collection);

  /// Atomically persists [body] as the JSON for [collection].
  Future<void> write(String collection, String body);

  /// Removes [collection] entirely.
  Future<void> remove(String collection);

  /// Preserves a corrupt [body] out of the way so it can't brick the app,
  /// leaving [collection] to start fresh.
  Future<void> quarantine(String collection, String body);

  /// Deletes all persisted data. [knownCollections] are collections touched
  /// this session, used by backends that cannot enumerate storage.
  Future<void> wipeAll(Iterable<String> knownCollections);
}

/// Creates the platform-appropriate backend. [prefs] is used by the web
/// backend and ignored by the file backend.
StoreBackend createStoreBackend(SharedPreferences? prefs) =>
    makeStoreBackend(prefs);
