/// Diet program domain model.
///
/// Content is versioned ([DietProgram.contentVersion]) and every program
/// carries evidence references and explicit limitations. No program is
/// presented as universally superior (master requirement §6).
library;

class EvidenceRef {
  const EvidenceRef({
    required this.title,
    required this.source,
    required this.year,
    this.note,
  });

  final String title;
  final String source;
  final String year;
  final String? note;
}

class MacroSplit {
  const MacroSplit({
    required this.proteinPct,
    required this.carbsPct,
    required this.fatPct,
  });

  final int proteinPct;
  final int carbsPct;
  final int fatPct;

  bool get isValid => proteinPct + carbsPct + fatPct == 100;
}

class FastingSchedule {
  const FastingSchedule({
    required this.id,
    required this.label,
    required this.fastingHours,
    required this.eatingHours,
  });

  final String id;
  final String label;
  final int fastingHours;
  final int eatingHours;
}

/// Supported gentle intermittent-fasting schedules. Prolonged or extreme
/// fasting is deliberately not offered (master requirement §6).
const List<FastingSchedule> supportedFastingSchedules = [
  FastingSchedule(
    id: '12_12',
    label: '12:12',
    fastingHours: 12,
    eatingHours: 12,
  ),
  FastingSchedule(
    id: '13_11',
    label: '13:11',
    fastingHours: 13,
    eatingHours: 11,
  ),
  FastingSchedule(
    id: '14_10',
    label: '14:10',
    fastingHours: 14,
    eatingHours: 10,
  ),
  FastingSchedule(id: '16_8', label: '16:8', fastingHours: 16, eatingHours: 8),
];

class DietProgram {
  const DietProgram({
    required this.id,
    required this.name,
    required this.tagline,
    required this.overview,
    required this.foodPattern,
    required this.benefits,
    required this.limitations,
    required this.seekGuidanceFirst,
    required this.sustainability,
    required this.difficulty,
    required this.sampleDay,
    required this.encouraged,
    required this.limited,
    required this.nutrientGaps,
    required this.evidence,
    required this.recipeTags,
    this.macroSplit,
    this.supportsFasting = false,
  });

  final String id;
  final String name;
  final String tagline;
  final String overview;
  final String foodPattern;
  final List<String> benefits;
  final List<String> limitations;

  /// Groups who should get professional guidance before starting.
  final List<String> seekGuidanceFirst;

  /// 1 (hard to keep up) … 5 (easy to sustain long-term).
  final int sustainability;

  /// 1 (easy) … 5 (demanding).
  final int difficulty;

  /// Meal name -> example content.
  final Map<String, String> sampleDay;
  final List<String> encouraged;
  final List<String> limited;
  final List<String> nutrientGaps;
  final List<EvidenceRef> evidence;

  /// Tags used by the meal planner to select compatible recipes.
  final List<String> recipeTags;
  final MacroSplit? macroSplit;
  final bool supportsFasting;

  /// Content version for reproducibility; bump when diet copy changes.
  static const String contentVersion = 'diet-content-v1';
}
