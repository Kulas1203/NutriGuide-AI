/// Food and nutrient domain models.
///
/// Every nutrition value in NutriGuide carries provenance ([NutritionSource])
/// so the UI can always distinguish verified database values from estimates
/// (master requirement §10). Estimated entries additionally expose the
/// assumptions used.
library;

enum NutritionSource {
  verified('Verified database', 'Values from USDA FoodData Central'),
  manufacturer('Manufacturer', 'Values from the product label'),
  userEntered('Your entry', 'Values you entered yourself'),
  recipeEstimate('Recipe estimate', 'Estimated from typical ingredients'),
  aiEstimate('AI estimate', 'Estimated by the AI Coach — treat as rough');

  const NutritionSource(this.label, this.description);
  final String label;
  final String description;
}

class Nutrients {
  const Nutrients({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 0,
    this.sodiumMg,
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double? sodiumMg;

  static const Nutrients zero = Nutrients(
    kcal: 0,
    proteinG: 0,
    carbsG: 0,
    fatG: 0,
  );

  Nutrients scale(double factor) => Nutrients(
    kcal: kcal * factor,
    proteinG: proteinG * factor,
    carbsG: carbsG * factor,
    fatG: fatG * factor,
    fiberG: fiberG * factor,
    sodiumMg: sodiumMg == null ? null : sodiumMg! * factor,
  );

  Nutrients operator +(Nutrients other) => Nutrients(
    kcal: kcal + other.kcal,
    proteinG: proteinG + other.proteinG,
    carbsG: carbsG + other.carbsG,
    fatG: fatG + other.fatG,
    fiberG: fiberG + other.fiberG,
    sodiumMg: sodiumMg == null && other.sodiumMg == null
        ? null
        : (sodiumMg ?? 0) + (other.sodiumMg ?? 0),
  );

  /// Energy computed from macros with Atwater factors; used by validators to
  /// reject implausible entries.
  double get atwaterKcal => proteinG * 4 + carbsG * 4 + fatG * 9;

  Map<String, dynamic> toJson() => {
    'kcal': kcal,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'fiberG': fiberG,
    'sodiumMg': sodiumMg,
  };

  factory Nutrients.fromJson(Map<String, dynamic> json) => Nutrients(
    kcal: (json['kcal'] as num).toDouble(),
    proteinG: (json['proteinG'] as num).toDouble(),
    carbsG: (json['carbsG'] as num).toDouble(),
    fatG: (json['fatG'] as num).toDouble(),
    fiberG: (json['fiberG'] as num?)?.toDouble() ?? 0,
    sodiumMg: (json['sodiumMg'] as num?)?.toDouble(),
  );
}

enum FoodCategory {
  grains('Grains & starches'),
  protein('Meat, fish & protein'),
  dairy('Dairy & eggs'),
  vegetables('Vegetables'),
  fruit('Fruit'),
  legumes('Legumes & nuts'),
  fats('Oils & fats'),
  dishes('Prepared dishes'),
  snacks('Snacks & sweets'),
  beverages('Beverages');

  const FoodCategory(this.label);
  final String label;
}

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.per100g,
    required this.servingName,
    required this.servingGrams,
    required this.source,
    this.sourceRef,
    this.brand,
    this.allergens = const [],
    this.tags = const [],
    this.assumptions,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final FoodCategory category;
  final Nutrients per100g;

  /// Friendly default serving, e.g. "1 cup, cooked".
  final String servingName;
  final double servingGrams;
  final NutritionSource source;

  /// Reference such as 'USDA FDC 171705'. Required for verified entries.
  final String? sourceRef;
  final String? brand;
  final List<String> allergens;

  /// Diet-compatibility tags, aligned with DietProgram.recipeTags.
  final List<String> tags;

  /// For estimated entries: the ingredient and serving assumptions used.
  final String? assumptions;
  final bool isCustom;

  bool get isEstimate =>
      source == NutritionSource.recipeEstimate ||
      source == NutritionSource.aiEstimate;

  Nutrients forGrams(double grams) => per100g.scale(grams / 100);
  Nutrients get perServing => forGrams(servingGrams);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'per100g': per100g.toJson(),
    'servingName': servingName,
    'servingGrams': servingGrams,
    'source': source.name,
    'sourceRef': sourceRef,
    'brand': brand,
    'allergens': allergens,
    'tags': tags,
    'assumptions': assumptions,
    'isCustom': isCustom,
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'] as String,
    name: json['name'] as String,
    category: FoodCategory.values.byName(json['category'] as String),
    per100g: Nutrients.fromJson(json['per100g'] as Map<String, dynamic>),
    servingName: json['servingName'] as String,
    servingGrams: (json['servingGrams'] as num).toDouble(),
    source: NutritionSource.values.byName(json['source'] as String),
    sourceRef: json['sourceRef'] as String?,
    brand: json['brand'] as String?,
    allergens: ((json['allergens'] as List?) ?? const []).cast<String>(),
    tags: ((json['tags'] as List?) ?? const []).cast<String>(),
    assumptions: json['assumptions'] as String?,
    isCustom: json['isCustom'] as bool? ?? false,
  );
}

/// Common allergens used for filtering and warnings. Users can also add
/// free-text allergies which are matched against food names and allergen tags.
abstract final class Allergens {
  static const List<String> common = [
    'peanut',
    'tree nut',
    'milk',
    'egg',
    'wheat',
    'gluten',
    'soy',
    'fish',
    'shellfish',
    'sesame',
  ];
}
