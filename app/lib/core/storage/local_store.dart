import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'store_backend.dart';

/// Local-first document store.
///
/// Persists `id -> document` maps per collection through a platform
/// [StoreBackend]: JSON files under the app documents directory on
/// Android/iOS, and [SharedPreferences] (browser localStorage) on the web,
/// where `dart:io` is unavailable. Either way the entire app is usable
/// offline; the sync layer (core/network/sync_service.dart) replays queued
/// mutations to the backend when connectivity returns.
///
/// This intentionally favors robustness over raw throughput: datasets here
/// are small (diary entries, plans, settings), disk writes are atomic, and
/// corruption of one collection cannot affect another.
class LocalStore {
  LocalStore({SharedPreferences? prefs})
    : _backend = createStoreBackend(prefs),
      _inMemory = false;

  /// In-memory store with no persistence, used by tests so async operations
  /// complete on the microtask queue (and therefore under fake-async pumps).
  LocalStore.inMemory() : _backend = null, _inMemory = true;

  final StoreBackend? _backend;
  final bool _inMemory;
  final Map<String, Map<String, Map<String, dynamic>>> _cache = {};

  Future<Map<String, Map<String, dynamic>>> _load(String collection) async {
    final cached = _cache[collection];
    if (cached != null) return cached;
    if (_inMemory) {
      final data = <String, Map<String, dynamic>>{};
      _cache[collection] = data;
      return data;
    }
    Map<String, Map<String, dynamic>> data = {};
    final raw = await _backend!.read(collection);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        data = decoded.map(
          (k, v) => MapEntry(k, (v as Map).cast<String, dynamic>()),
        );
      } on FormatException catch (e) {
        // A corrupt collection must not brick the app: preserve it for
        // diagnosis and start the collection fresh.
        debugPrint('LocalStore: corrupt collection $collection: $e');
        await _backend.quarantine(collection, raw);
      }
    }
    _cache[collection] = data;
    return data;
  }

  Future<void> _flush(String collection) async {
    if (_inMemory) return;
    await _backend!.write(collection, jsonEncode(_cache[collection] ?? {}));
  }

  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    final data = await _load(collection);
    return data.values.map(Map<String, dynamic>.from).toList();
  }

  Future<Map<String, dynamic>?> get(String collection, String id) async {
    final data = await _load(collection);
    final doc = data[id];
    return doc == null ? null : Map<String, dynamic>.from(doc);
  }

  Future<void> put(
    String collection,
    String id,
    Map<String, dynamic> document,
  ) async {
    final data = await _load(collection);
    data[id] = Map<String, dynamic>.from(document);
    await _flush(collection);
  }

  Future<void> putAll(
    String collection,
    Map<String, Map<String, dynamic>> documents,
  ) async {
    final data = await _load(collection);
    documents.forEach((id, doc) {
      data[id] = Map<String, dynamic>.from(doc);
    });
    await _flush(collection);
  }

  Future<void> delete(String collection, String id) async {
    final data = await _load(collection);
    data.remove(id);
    await _flush(collection);
  }

  Future<void> clearCollection(String collection) async {
    _cache[collection] = {};
    await _flush(collection);
  }

  /// Deletes every collection. Used by account deletion.
  Future<void> wipeAll() async {
    final touched = _cache.keys.toList();
    _cache.clear();
    if (_inMemory) return;
    await _backend!.wipeAll(touched);
  }

  /// Full export of all collections, used by the data-export feature.
  Future<Map<String, dynamic>> exportAll(List<String> collections) async {
    final result = <String, dynamic>{};
    for (final c in collections) {
      result[c] = await _load(c);
    }
    return jsonDecode(jsonEncode(result)) as Map<String, dynamic>;
  }
}
