import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/recipe.dart';

/// Loads the bundled recipe dataset used by the meal planner.
class RecipeRepository {
  RecipeRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  List<Recipe>? _cache;

  Future<List<Recipe>> all() async {
    if (_cache != null) return _cache!;
    final raw = await _bundle.loadString('assets/data/recipes.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (decoded['items'] as List)
        .map((e) => Recipe.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return _cache!;
  }

  Future<Map<String, Recipe>> byIdMap() async {
    final list = await all();
    return {for (final r in list) r.id: r};
  }

  Future<Recipe?> byId(String id) async {
    final map = await byIdMap();
    return map[id];
  }
}
