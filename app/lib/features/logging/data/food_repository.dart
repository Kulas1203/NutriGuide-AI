import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/storage/local_store.dart';
import '../domain/food_item.dart';

/// Loads the bundled verified/estimated food dataset and merges user-created
/// custom foods from local storage. Custom foods sync per-user to the
/// backend; bundled foods ship with the app.
class FoodRepository {
  FoodRepository(this._store, {AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final LocalStore _store;
  final AssetBundle _bundle;
  static const String _customCollection = 'custom_foods';

  List<FoodItem>? _bundled;

  Future<List<FoodItem>> _loadBundled() async {
    if (_bundled != null) return _bundled!;
    final raw = await _bundle.loadString('assets/data/foods.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _bundled = (decoded['items'] as List)
        .map((e) => FoodItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return _bundled!;
  }

  Future<List<FoodItem>> all() async {
    final bundled = await _loadBundled();
    final customRaw = await _store.getAll(_customCollection);
    final custom = customRaw.map(FoodItem.fromJson).toList();
    return [...custom, ...bundled];
  }

  /// Case-insensitive search over name and brand, custom foods first.
  Future<List<FoodItem>> search(String query, {int limit = 40}) async {
    final q = query.trim().toLowerCase();
    final items = await all();
    if (q.isEmpty) return items.take(limit).toList();
    final scored = <(int, FoodItem)>[];
    for (final item in items) {
      final name = item.name.toLowerCase();
      final brand = item.brand?.toLowerCase() ?? '';
      int score;
      if (name == q) {
        score = 0;
      } else if (name.startsWith(q)) {
        score = 1;
      } else if (name.contains(q)) {
        score = 2;
      } else if (brand.contains(q) || item.tags.contains(q)) {
        score = 3;
      } else {
        continue;
      }
      scored.add((score, item));
    }
    scored.sort((a, b) => a.$1.compareTo(b.$1));
    return scored.take(limit).map((e) => e.$2).toList();
  }

  Future<FoodItem?> byId(String id) async {
    final items = await all();
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> saveCustom(FoodItem item) =>
      _store.put(_customCollection, item.id, item.toJson());

  Future<void> deleteCustom(String id) => _store.delete(_customCollection, id);
}
