import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Local-first document store.
///
/// Each collection is a JSON file under the app documents directory
/// (`nutriguide/<collection>.json`) holding `id -> document` maps. All feature
/// repositories persist through this store, which makes the entire app usable
/// offline; the sync layer (core/network/sync_service.dart) replays queued
/// mutations to the backend when connectivity returns.
///
/// This intentionally favors robustness over raw throughput: datasets here
/// are small (diary entries, plans, settings), writes are atomic
/// (write-to-temp + rename), and corruption of one collection cannot affect
/// another.
class LocalStore {
  LocalStore({Directory? baseDirectory})
    : _baseOverride = baseDirectory,
      _inMemory = false;

  /// In-memory store with no disk I/O, used by tests so async operations
  /// complete on the microtask queue (and therefore under fake-async pumps).
  LocalStore.inMemory() : _baseOverride = null, _inMemory = true;

  final Directory? _baseOverride;
  final bool _inMemory;
  final Map<String, Map<String, Map<String, dynamic>>> _cache = {};
  Directory? _base;

  Future<Directory> _baseDir() async {
    if (_base != null) return _base!;
    final root = _baseOverride ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/nutriguide');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _base = dir;
    return dir;
  }

  File _fileFor(Directory base, String collection) =>
      File('${base.path}/$collection.json');

  Future<Map<String, Map<String, dynamic>>> _load(String collection) async {
    final cached = _cache[collection];
    if (cached != null) return cached;
    if (_inMemory) {
      final data = <String, Map<String, dynamic>>{};
      _cache[collection] = data;
      return data;
    }
    final base = await _baseDir();
    final file = _fileFor(base, collection);
    Map<String, Map<String, dynamic>> data = {};
    if (file.existsSync()) {
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        data = decoded.map(
          (k, v) => MapEntry(k, (v as Map).cast<String, dynamic>()),
        );
      } on FormatException catch (e) {
        // A corrupt file must not brick the app: preserve it for diagnosis
        // and start the collection fresh.
        debugPrint('LocalStore: corrupt collection $collection: $e');
        await file.rename('${file.path}.corrupt');
      }
    }
    _cache[collection] = data;
    return data;
  }

  Future<void> _flush(String collection) async {
    if (_inMemory) return;
    final base = await _baseDir();
    final file = _fileFor(base, collection);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(_cache[collection] ?? {}));
    await tmp.rename(file.path);
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

  /// Deletes every collection on disk. Used by account deletion.
  Future<void> wipeAll() async {
    _cache.clear();
    if (_inMemory) return;
    final base = await _baseDir();
    if (base.existsSync()) {
      await base.delete(recursive: true);
      base.createSync(recursive: true);
    }
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
