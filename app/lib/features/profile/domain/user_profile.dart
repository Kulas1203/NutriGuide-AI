/// User profile domain model.
///
/// All measurements are stored metric (see core/utils/units.dart). Optional
/// health-related fields are nullable and clearly separated; they are only
/// used to adapt guidance and safety messaging, never for advertising or
/// analytics (see docs/DATA_SAFETY_MAPPING.md).
library;

enum ActivityLevel {
  sedentary('Sedentary', 'Mostly sitting, little planned activity', 1.2),
  light('Lightly active', 'Light activity or walks 1–3 days a week', 1.375),
  moderate('Moderately active', 'Moderate exercise 3–5 days a week', 1.55),
  active('Active', 'Hard exercise 6–7 days a week', 1.725),
  veryActive('Very active', 'Physical job plus regular hard training', 1.9);

  const ActivityLevel(this.label, this.description, this.multiplier);
  final String label;
  final String description;
  final double multiplier;
}

enum WellnessGoal {
  loseWeight('Gradual weight loss'),
  maintain('Maintain and feel good'),
  gainWeight('Healthy weight gain'),
  buildMuscle('Build strength and muscle'),
  improveHabits('Build better eating habits');

  const WellnessGoal(this.label);
  final String label;
}

enum BiologicalSex {
  female('Female'),
  male('Male'),
  unspecified('Prefer not to say');

  const BiologicalSex(this.label);
  final String label;
}

/// Health considerations that require restricting personalized
/// recommendations and advising professional consultation (master
/// requirement §2). Selecting any of these sets
/// [UserProfile.requiresProfessionalGuidance].
enum HealthFlag {
  pregnancy('Pregnant or breastfeeding'),
  eatingDisorderHistory('History or signs of an eating disorder'),
  diabetesOnMedication('Diabetes requiring medication'),
  kidneyDisease('Kidney disease'),
  liverDisease('Liver disease'),
  cardiovascularDisease('Cardiovascular disease'),
  severeFoodAllergy('Severe food allergies (e.g. anaphylaxis)'),
  cancerTreatment('Currently in cancer treatment'),
  recentSurgery('Recent major surgery'),
  medicationAffectedByFood('Taking medicines affected by food intake'),
  rapidWeightLoss('Unexplained rapid weight loss'),
  urgentSymptoms('Fainting, chest pain, confusion or other urgent symptoms');

  const HealthFlag(this.label);
  final String label;
}

enum CookingTime {
  quick('Under 20 minutes'),
  moderate('20–45 minutes'),
  elaborate('I enjoy longer cooking');

  const CookingTime(this.label);
  final String label;
}

enum BudgetPreference {
  low('Budget-friendly'),
  medium('Moderate'),
  high('Flexible');

  const BudgetPreference(this.label);
  final String label;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.isAdultConfirmed,
    required this.country,
    required this.language,
    required this.metricUnits,
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.sex,
    required this.activityLevel,
    required this.goal,
    required this.dietId,
    required this.allergies,
    required this.avoidFoods,
    required this.mealsPerDay,
    required this.cookingTime,
    required this.budget,
    required this.consentVersion,
    required this.disclaimerAcknowledgedAt,
    this.targetWeightKg,
    this.targetDate,
    this.sleepSchedule,
    this.workSchedule,
    this.cookingSkill,
    this.kitchenEquipment = const [],
    this.preferredCuisines = const [],
    this.culturalRestrictions = const [],
    this.healthFlags = const [],
    this.medicationTimingNote,
    this.aiHistoryEnabled = true,
    this.hideWeightFeatures = false,
    this.updatedAt,
  });

  final String id;
  final String displayName;

  /// The user explicitly confirmed being 18 or older during onboarding.
  final bool isAdultConfirmed;
  final String country;
  final String language;
  final bool metricUnits;
  final double heightCm;
  final double weightKg;
  final int age;
  final BiologicalSex sex;
  final ActivityLevel activityLevel;
  final WellnessGoal goal;

  /// Selected diet program id (see features/diets/domain/diet_catalog.dart).
  final String dietId;
  final List<String> allergies;
  final List<String> avoidFoods;
  final int mealsPerDay;
  final CookingTime cookingTime;
  final BudgetPreference budget;

  /// Version of the disclaimer/consent text acknowledged by the user, with
  /// timestamp. Consent history is kept server-side as well.
  final String consentVersion;
  final DateTime disclaimerAcknowledgedAt;

  // Optional fields — all skippable in onboarding, all editable later.
  final double? targetWeightKg;
  final DateTime? targetDate;
  final String? sleepSchedule;
  final String? workSchedule;
  final String? cookingSkill;
  final List<String> kitchenEquipment;
  final List<String> preferredCuisines;
  final List<String> culturalRestrictions;
  final List<HealthFlag> healthFlags;
  final String? medicationTimingNote;

  // Privacy and presentation controls.
  final bool aiHistoryEnabled;
  final bool hideWeightFeatures;
  final DateTime? updatedAt;

  /// True when the profile indicates a condition for which personalized diet
  /// recommendations must be restricted (master requirement §2).
  bool get requiresProfessionalGuidance => healthFlags.isNotEmpty;

  /// True when the user reported urgent symptoms; surfaces an immediate-care
  /// notice and suppresses recommendation flows.
  bool get hasUrgentSymptoms => healthFlags.contains(HealthFlag.urgentSymptoms);

  UserProfile copyWith({
    String? displayName,
    String? country,
    String? language,
    bool? metricUnits,
    double? heightCm,
    double? weightKg,
    int? age,
    BiologicalSex? sex,
    ActivityLevel? activityLevel,
    WellnessGoal? goal,
    String? dietId,
    List<String>? allergies,
    List<String>? avoidFoods,
    int? mealsPerDay,
    CookingTime? cookingTime,
    BudgetPreference? budget,
    Object? targetWeightKg = _sentinel,
    Object? targetDate = _sentinel,
    List<String>? preferredCuisines,
    List<String>? culturalRestrictions,
    List<HealthFlag>? healthFlags,
    Object? medicationTimingNote = _sentinel,
    bool? aiHistoryEnabled,
    bool? hideWeightFeatures,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      isAdultConfirmed: isAdultConfirmed,
      country: country ?? this.country,
      language: language ?? this.language,
      metricUnits: metricUnits ?? this.metricUnits,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      dietId: dietId ?? this.dietId,
      allergies: allergies ?? this.allergies,
      avoidFoods: avoidFoods ?? this.avoidFoods,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      cookingTime: cookingTime ?? this.cookingTime,
      budget: budget ?? this.budget,
      consentVersion: consentVersion,
      disclaimerAcknowledgedAt: disclaimerAcknowledgedAt,
      targetWeightKg: targetWeightKg == _sentinel
          ? this.targetWeightKg
          : targetWeightKg as double?,
      targetDate: targetDate == _sentinel
          ? this.targetDate
          : targetDate as DateTime?,
      sleepSchedule: sleepSchedule,
      workSchedule: workSchedule,
      cookingSkill: cookingSkill,
      kitchenEquipment: kitchenEquipment,
      preferredCuisines: preferredCuisines ?? this.preferredCuisines,
      culturalRestrictions: culturalRestrictions ?? this.culturalRestrictions,
      healthFlags: healthFlags ?? this.healthFlags,
      medicationTimingNote: medicationTimingNote == _sentinel
          ? this.medicationTimingNote
          : medicationTimingNote as String?,
      aiHistoryEnabled: aiHistoryEnabled ?? this.aiHistoryEnabled,
      hideWeightFeatures: hideWeightFeatures ?? this.hideWeightFeatures,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static const Object _sentinel = Object();

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'isAdultConfirmed': isAdultConfirmed,
    'country': country,
    'language': language,
    'metricUnits': metricUnits,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'age': age,
    'sex': sex.name,
    'activityLevel': activityLevel.name,
    'goal': goal.name,
    'dietId': dietId,
    'allergies': allergies,
    'avoidFoods': avoidFoods,
    'mealsPerDay': mealsPerDay,
    'cookingTime': cookingTime.name,
    'budget': budget.name,
    'consentVersion': consentVersion,
    'disclaimerAcknowledgedAt': disclaimerAcknowledgedAt.toIso8601String(),
    'targetWeightKg': targetWeightKg,
    'targetDate': targetDate?.toIso8601String(),
    'sleepSchedule': sleepSchedule,
    'workSchedule': workSchedule,
    'cookingSkill': cookingSkill,
    'kitchenEquipment': kitchenEquipment,
    'preferredCuisines': preferredCuisines,
    'culturalRestrictions': culturalRestrictions,
    'healthFlags': healthFlags.map((f) => f.name).toList(),
    'medicationTimingNote': medicationTimingNote,
    'aiHistoryEnabled': aiHistoryEnabled,
    'hideWeightFeatures': hideWeightFeatures,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        ((json[key] as List?) ?? const []).cast<String>();
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      isAdultConfirmed: json['isAdultConfirmed'] as bool? ?? false,
      country: json['country'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      metricUnits: json['metricUnits'] as bool? ?? true,
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      age: json['age'] as int,
      sex: BiologicalSex.values.byName(json['sex'] as String? ?? 'unspecified'),
      activityLevel: ActivityLevel.values.byName(
        json['activityLevel'] as String? ?? 'light',
      ),
      goal: WellnessGoal.values.byName(json['goal'] as String? ?? 'maintain'),
      dietId: json['dietId'] as String? ?? 'balanced',
      allergies: strings('allergies'),
      avoidFoods: strings('avoidFoods'),
      mealsPerDay: json['mealsPerDay'] as int? ?? 3,
      cookingTime: CookingTime.values.byName(
        json['cookingTime'] as String? ?? 'moderate',
      ),
      budget: BudgetPreference.values.byName(
        json['budget'] as String? ?? 'medium',
      ),
      consentVersion: json['consentVersion'] as String? ?? '',
      disclaimerAcknowledgedAt: DateTime.parse(
        json['disclaimerAcknowledgedAt'] as String,
      ),
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      targetDate: json['targetDate'] == null
          ? null
          : DateTime.parse(json['targetDate'] as String),
      sleepSchedule: json['sleepSchedule'] as String?,
      workSchedule: json['workSchedule'] as String?,
      cookingSkill: json['cookingSkill'] as String?,
      kitchenEquipment: strings('kitchenEquipment'),
      preferredCuisines: strings('preferredCuisines'),
      culturalRestrictions: strings('culturalRestrictions'),
      healthFlags: ((json['healthFlags'] as List?) ?? const [])
          .cast<String>()
          .map(HealthFlag.values.byName)
          .toList(),
      medicationTimingNote: json['medicationTimingNote'] as String?,
      aiHistoryEnabled: json['aiHistoryEnabled'] as bool? ?? true,
      hideWeightFeatures: json['hideWeightFeatures'] as bool? ?? false,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );
  }
}
