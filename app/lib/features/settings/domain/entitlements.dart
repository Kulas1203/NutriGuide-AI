/// Subscription entitlement logic.
///
/// Monetization ships behind a feature flag (master requirement §18): when
/// [FeatureFlags.monetizationEnabled] is false — the launch default — every
/// feature runs in the generous free configuration and no billing UI exists.
/// The Google Play Billing integration slot is documented in
/// docs/ARCHITECTURE.md §Monetization.
library;

class FeatureFlags {
  const FeatureFlags({
    this.monetizationEnabled = false,
    this.aiCoachEnabled = true,
    this.freeAiQuestionsPerDay = 15,
    this.premiumAiQuestionsPerDay = 150,
  });

  final bool monetizationEnabled;
  final bool aiCoachEnabled;
  final int freeAiQuestionsPerDay;

  /// Fair-use limit for premium ("unlimited subject to fair use").
  final int premiumAiQuestionsPerDay;

  factory FeatureFlags.fromJson(Map<String, dynamic> json) => FeatureFlags(
    monetizationEnabled: json['monetizationEnabled'] as bool? ?? false,
    aiCoachEnabled: json['aiCoachEnabled'] as bool? ?? true,
    freeAiQuestionsPerDay: json['freeAiQuestionsPerDay'] as int? ?? 15,
    premiumAiQuestionsPerDay: json['premiumAiQuestionsPerDay'] as int? ?? 150,
  );

  Map<String, dynamic> toJson() => {
    'monetizationEnabled': monetizationEnabled,
    'aiCoachEnabled': aiCoachEnabled,
    'freeAiQuestionsPerDay': freeAiQuestionsPerDay,
    'premiumAiQuestionsPerDay': premiumAiQuestionsPerDay,
  };
}

enum SubscriptionTier { free, premium }

class Entitlements {
  const Entitlements({required this.tier, required this.flags});

  final SubscriptionTier tier;
  final FeatureFlags flags;

  /// AI questions allowed per day for this user.
  int get aiQuestionsPerDay {
    if (!flags.monetizationEnabled) {
      // Launch configuration: monetization off, everyone gets the free tier
      // allowance which is sized to be genuinely useful.
      return flags.freeAiQuestionsPerDay;
    }
    return switch (tier) {
      SubscriptionTier.free => flags.freeAiQuestionsPerDay,
      SubscriptionTier.premium => flags.premiumAiQuestionsPerDay,
    };
  }

  bool get advancedAnalytics =>
      !flags.monetizationEnabled || tier == SubscriptionTier.premium;

  bool get multipleSavedPrograms =>
      !flags.monetizationEnabled || tier == SubscriptionTier.premium;

  /// Account deletion and data export are NEVER gated by subscription.
  bool get canDeleteAccount => true;
  bool get canExportData => true;

  bool canAskAiQuestion(int questionsAskedToday) =>
      flags.aiCoachEnabled && questionsAskedToday < aiQuestionsPerDay;
}
