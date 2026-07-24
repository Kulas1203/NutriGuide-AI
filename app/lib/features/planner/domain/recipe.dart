import '../../logging/domain/food_item.dart';

class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.grams,
    this.note,
    this.substitutes = const [],
  });

  final String name;
  final double grams;
  final String? note;

  /// Suggested swaps preserving the dish, e.g. tofu for chicken.
  final List<String> substitutes;

  Map<String, dynamic> toJson() => {
    'name': name,
    'grams': grams,
    'note': note,
    'substitutes': substitutes,
  };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        name: json['name'] as String,
        grams: (json['grams'] as num).toDouble(),
        note: json['note'] as String?,
        substitutes: ((json['substitutes'] as List?) ?? const [])
            .cast<String>(),
      );
}

enum MealSlot {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snack');

  const MealSlot(this.label);
  final String label;
}

/// Cost tier: 1 budget-friendly, 2 moderate, 3 flexible.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.cuisine,
    required this.slots,
    required this.servings,
    required this.prepMinutes,
    required this.ingredients,
    required this.steps,
    required this.perServing,
    required this.source,
    required this.tags,
    this.allergens = const [],
    this.costTier = 2,
    this.sourceRef,
    this.assumptions,
    this.groceryCategory = const {},
  });

  final String id;
  final String name;
  final String description;
  final String cuisine;
  final List<MealSlot> slots;
  final int servings;
  final int prepMinutes;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final Nutrients perServing;
  final NutritionSource source;
  final List<String> tags;
  final List<String> allergens;
  final int costTier;
  final String? sourceRef;

  /// For estimated recipes: serving and ingredient assumptions, always shown
  /// in the UI (master requirement §8: no fabricated local food values).
  final String? assumptions;

  /// ingredient name -> grocery aisle category.
  final Map<String, String> groceryCategory;

  bool get isEstimate => source == NutritionSource.recipeEstimate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'cuisine': cuisine,
    'slots': slots.map((s) => s.name).toList(),
    'servings': servings,
    'prepMinutes': prepMinutes,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'steps': steps,
    'perServing': perServing.toJson(),
    'source': source.name,
    'tags': tags,
    'allergens': allergens,
    'costTier': costTier,
    'sourceRef': sourceRef,
    'assumptions': assumptions,
    'groceryCategory': groceryCategory,
  };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    cuisine: json['cuisine'] as String,
    slots: ((json['slots'] as List?) ?? const [])
        .cast<String>()
        .map(MealSlot.values.byName)
        .toList(),
    servings: json['servings'] as int,
    prepMinutes: json['prepMinutes'] as int,
    ingredients: ((json['ingredients'] as List?) ?? const [])
        .map(
          (i) => RecipeIngredient.fromJson((i as Map).cast<String, dynamic>()),
        )
        .toList(),
    steps: ((json['steps'] as List?) ?? const []).cast<String>(),
    perServing: Nutrients.fromJson(json['perServing'] as Map<String, dynamic>),
    source: NutritionSource.values.byName(json['source'] as String),
    tags: ((json['tags'] as List?) ?? const []).cast<String>(),
    allergens: ((json['allergens'] as List?) ?? const []).cast<String>(),
    costTier: json['costTier'] as int? ?? 2,
    sourceRef: json['sourceRef'] as String?,
    assumptions: json['assumptions'] as String?,
    groceryCategory: ((json['groceryCategory'] as Map?) ?? const {})
        .cast<String, String>(),
  );
}
