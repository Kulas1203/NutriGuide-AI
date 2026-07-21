/// Centralized disclaimer and consent text.
///
/// The product limitation statement below is shown verbatim in onboarding,
/// before the first AI conversation, in the AI info screen, in Settings, in
/// the Privacy & Safety section, and in the store listing (master
/// requirement §1). [consentVersion] is recorded with each acknowledgment so
/// consent history is auditable.
abstract final class Consent {
  static const String consentVersion = '2026-07-01';

  /// The required product statement, shown wherever the disclaimer appears.
  static const String productStatement =
      'NutriGuide AI provides educational nutrition information, '
      'meal-planning assistance, food tracking, and general wellness '
      'guidance. It does not diagnose, treat, cure, or prevent medical '
      'conditions and is not a substitute for advice from a physician or '
      'registered dietitian.';

  static const String aiCoachStatement =
      'The AI Nutrition Coach offers general educational information. It is '
      'not a doctor, not a registered dietitian, and is not always correct. '
      'It can make mistakes. For anything involving a medical condition, '
      'medication, pregnancy, or symptoms, please consult a qualified '
      'professional.';

  static const String adultConfirmation =
      'I confirm that I am at least 18 years old.';

  static const String dataConsent =
      'I understand that NutriGuide stores the diet, body-measurement and '
      'wellness information I choose to provide to personalize my '
      'experience, and that I can export or delete it at any time.';

  /// Shown when the user reports a condition needing professional guidance.
  static const String professionalGuidanceNotice =
      'Based on what you shared, NutriGuide will keep its guidance general '
      'and will not create therapeutic meal plans for medical conditions. '
      'Please work with your physician or a registered dietitian for '
      'personalized care.';
}
