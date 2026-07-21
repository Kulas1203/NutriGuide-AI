/// Client-side safety pre-screen for the AI Nutrition Coach.
///
/// This runs BEFORE any message leaves the device. It is a fast,
/// conservative keyword/pattern classifier; the authoritative safety layer
/// runs server-side (backend/functions/src/safety/classifier.ts) on every
/// request. Both layers are exercised by the versioned evaluation suite in
/// ai_evals/.
///
/// Design rules (master requirement §8):
/// - urgent-care situations get an immediate care message, never a diet
///   answer first;
/// - eating-disorder and self-harm signals get supportive resources, never
///   restriction advice;
/// - medication/disease-management questions are answered only with a
///   professional-referral framing.
library;

enum SafetyCategory {
  emergency,
  selfHarm,
  eatingDisorder,
  dangerousFasting,
  severeRestriction,
  childDieting,
  pregnancy,
  medication,
  diseaseManagement,
  none,
}

enum SafetyAction {
  /// Do not send to the model. Show urgent-care guidance.
  blockEmergency,

  /// Do not send to the model. Show supportive professional-referral message.
  blockRefer,

  /// Send to the model with a safety context flag; show a caution banner.
  allowWithCaution,

  allow,
}

class SafetyResult {
  const SafetyResult({
    required this.category,
    required this.action,
    this.userMessage,
  });

  final SafetyCategory category;
  final SafetyAction action;

  /// Message shown instead of (or alongside) an AI answer.
  final String? userMessage;
}

abstract final class SafetyMessages {
  static const String emergency =
      'Some of what you described can be signs of a medical emergency. '
      'Please contact your local emergency number or seek immediate medical '
      'care now. This app cannot help with urgent symptoms, and no nutrition '
      'advice should come before your safety.';

  static const String selfHarm =
      'It sounds like you might be going through something really hard right '
      'now. You deserve support from a real person: please reach out to a '
      'mental-health professional, someone you trust, or a crisis line in '
      'your country (in the Philippines, the NCMH Crisis Hotline at 1553; '
      'internationally, findahelpline.com lists local services). This app '
      'is not able to provide the help you need, and that is about our '
      'limits, not about you.';

  static const String eatingDisorder =
      'We want to be careful here. Some of what you wrote sounds like it '
      'could relate to a difficult relationship with food, and calorie or '
      'diet advice would not be the right thing for us to give. A physician, '
      'a registered dietitian, or an eating-disorder helpline can offer '
      'support that actually helps. You deserve care, not restriction.';

  static const String dangerousFasting =
      'NutriGuide supports gentle fasting schedules only (up to 16:8). '
      'Longer or stricter fasting can be genuinely risky and is not '
      'something we will help plan. If you are considering extended '
      'fasting, please talk to a physician first.';

  static const String severeRestriction =
      'We cannot help plan intakes that low — eating far below your '
      'estimated needs can be harmful. Our plans keep a safety minimum. If '
      'you feel you need faster results, a registered dietitian or physician '
      'can supervise safe options that we cannot.';

  static const String childDieting =
      'NutriGuide is designed for adults (18+). Diet plans for children and '
      'teenagers need professional supervision because their needs are '
      'different — please consult a pediatrician or registered dietitian.';

  static const String medication =
      'Questions involving medication — doses, timing, stopping, or food '
      'interactions — must go to your physician or pharmacist. We can share '
      'general food knowledge, but nothing we say should change how you '
      'take a prescribed medicine.';

  static const String diseaseManagement =
      'Managing a diagnosed condition with diet needs personalized '
      'professional care, so we will keep our answer general and encourage '
      'you to work with your care team or a registered dietitian.';

  static const String pregnancy =
      'Nutrition during pregnancy or breastfeeding needs individual '
      'professional guidance, so we will keep this general. Please review '
      'any diet change with your OB or midwife. Weight-loss dieting during '
      'pregnancy is generally not recommended.';
}

class SafetyClassifier {
  /// Version recorded with evaluations; keep in sync with the server
  /// classifier when patterns change.
  static const String version = 'safety-v1';

  static final List<(SafetyCategory, RegExp)> _blockingPatterns = [
    (
      SafetyCategory.emergency,
      RegExp(
        r'(chest pain|can.?t breathe|cannot breathe|passing out|passed out|'
        r'fainted|fainting|keep vomiting|vomiting blood|severe (pain|'
        r'weakness)|confus(ed|ion) and|heart attack|stroke|unconscious|'
        r'seizure)',
        caseSensitive: false,
      ),
    ),
    (
      SafetyCategory.selfHarm,
      RegExp(
        r'(kill myself|end my life|suicide|self.?harm|hurt myself|'
        r'don.?t want to (live|be alive)|starve myself to death)',
        caseSensitive: false,
      ),
    ),
    (
      SafetyCategory.eatingDisorder,
      RegExp(
        r'(purge|purging|throw up after (eating|meals)|make myself (sick|'
        r'vomit)|laxative.* (to )?lose|binge and|hate my body so much|'
        r'punish myself for eating|chew and spit|hiding (food|eating)|'
        r'terrified of (food|eating|calories))',
        caseSensitive: false,
      ),
    ),
    (
      SafetyCategory.dangerousFasting,
      RegExp(
        r'(fast(ing)? for (more than )?(2|3|4|5|6|7|\d{2,}) days|'
        r'\d+[ -]?days?[ -](water |dry )?fast|'
        r'(48|72|96)[ -]?hours? fast|dry fast|water fast|'
        r'not eat(en|ing)? for \d+ days|multi.?day fast)',
        caseSensitive: false,
      ),
    ),
    (
      SafetyCategory.severeRestriction,
      RegExp(
        r'((300|400|500|600|700|800)\s?(k?cal|calories)( a| per)? day|'
        r'eat (almost )?nothing|zero calorie diet|starvation diet|'
        r'lose \d+ ?kg in (a|one|1|2|two) week)',
        caseSensitive: false,
      ),
    ),
    (
      SafetyCategory.childDieting,
      RegExp(
        r'(my (son|daughter|child|kid)|for a (child|kid|teen(ager)?)|'
        r'(1[0-7]|[5-9])[ -]?year[ -]?old).{0,40}(diet|weight|calorie|'
        r'lose|slim)',
        caseSensitive: false,
      ),
    ),
  ];

  static final List<(SafetyCategory, RegExp)> _cautionPatterns = [
    (
      SafetyCategory.medication,
      RegExp(
        r'(insulin|metformin|warfarin|blood thinner|dosage|my medication|'
        r'stop taking|skip my (meds|medication|dose)|prescri(bed|ption))',
        caseSensitive: false,
      ),
    ),
    (
      SafetyCategory.diseaseManagement,
      RegExp(
        r'(diabet(es|ic)|kidney (disease|failure)|dialysis|liver (disease|'
        r'cirrhosis)|heart (disease|failure)|cancer|chemo(therapy)?|'
        r'hypertension|high blood pressure|thyroid)',
        caseSensitive: false,
      ),
    ),
    (
      SafetyCategory.pregnancy,
      RegExp(
        r'(pregnan(t|cy)|breastfeeding|nursing my|trying to conceive|'
        r'postpartum)',
        caseSensitive: false,
      ),
    ),
  ];

  SafetyResult classify(String message) {
    final text = message.trim();
    if (text.isEmpty) {
      return const SafetyResult(
        category: SafetyCategory.none,
        action: SafetyAction.allow,
      );
    }
    for (final (category, pattern) in _blockingPatterns) {
      if (pattern.hasMatch(text)) {
        return SafetyResult(
          category: category,
          action:
              category == SafetyCategory.emergency ||
                  category == SafetyCategory.selfHarm
              ? SafetyAction.blockEmergency
              : SafetyAction.blockRefer,
          userMessage: _messageFor(category),
        );
      }
    }
    for (final (category, pattern) in _cautionPatterns) {
      if (pattern.hasMatch(text)) {
        return SafetyResult(
          category: category,
          action: SafetyAction.allowWithCaution,
          userMessage: _messageFor(category),
        );
      }
    }
    return const SafetyResult(
      category: SafetyCategory.none,
      action: SafetyAction.allow,
    );
  }

  static String _messageFor(SafetyCategory category) => switch (category) {
    SafetyCategory.emergency => SafetyMessages.emergency,
    SafetyCategory.selfHarm => SafetyMessages.selfHarm,
    SafetyCategory.eatingDisorder => SafetyMessages.eatingDisorder,
    SafetyCategory.dangerousFasting => SafetyMessages.dangerousFasting,
    SafetyCategory.severeRestriction => SafetyMessages.severeRestriction,
    SafetyCategory.childDieting => SafetyMessages.childDieting,
    SafetyCategory.medication => SafetyMessages.medication,
    SafetyCategory.diseaseManagement => SafetyMessages.diseaseManagement,
    SafetyCategory.pregnancy => SafetyMessages.pregnancy,
    SafetyCategory.none => '',
  };
}
