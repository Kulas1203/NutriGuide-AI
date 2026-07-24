import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'store_backend.dart';

/// File-based backend for Android/iOS. Collections live as JSON files under
/// the app documents directory (`nutriguide/<collection>.json`); writes are
/// atomic (write-to-temp + rename) so a crash mid-write cannot corrupt data.
class _IoStoreBackend implements StoreBackend {
  Directory? _base;

  Future<Directory> _baseDir() async {
    if (_base != null) return _base!;
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/nutriguide');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _base = dir;
    return dir;
  }

  Future<File> _fileFor(String collection) async =>
      File('${(await _baseDir()).path}/$collection.json');

  @override
  Future<String?> read(String collection) async {
    final file = await _fileFor(collection);
    if (!file.existsSync()) return null;
    return file.readAsString();
  }

  @override
  Future<void> write(String collection, String body) async {
    final file = await _fileFor(collection);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(body);
    await tmp.rename(file.path);
  }

  @override
  Future<void> remove(String collection) async {
    final file = await _fileFor(collection);
    if (file.existsSync()) await file.delete();
  }

  @override
  Future<void> quarantine(String collection, String body) async {
    final file = await _fileFor(collection);
    if (file.existsSync()) await file.rename('${file.path}.corrupt');
  }

  @override
  Future<void> wipeAll(Iterable<String> knownCollections) async {
    final base = await _baseDir();
    if (base.existsSync()) {
      await base.delete(recursive: true);
      base.createSync(recursive: true);
    }
  }
}

/// Factory referenced by the conditional import in store_backend.dart.
StoreBackend makeStoreBackend(SharedPreferences? prefs) => _IoStoreBackend();
