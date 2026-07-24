import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_ai/features/diets/domain/diet_program.dart';
import 'package:nutriguide_ai/features/fasting/domain/fasting_session.dart';
import 'package:nutriguide_ai/features/settings/domain/entitlements.dart';

void main() {
  group('FastingSession', () {
    final start = DateTime(2026, 7, 21, 20);

    test('elapsed excludes accumulated pause', () {
      final s = FastingSession(
        id: 'f',
        scheduleId: '16_8',
        targetHours: 16,
        startedAt: start,
        accumulatedPause: const Duration(hours: 1),
      );
      final now = start.add(const Duration(hours: 5));
      expect(s.elapsed(now), const Duration(hours: 4));
    });

    test('paused time does not accrue', () {
      final s = FastingSession(
        id: 'f',
        scheduleId: '16_8',
        targetHours: 16,
        startedAt: start,
        status: FastingStatus.paused,
        pausedAt: start.add(const Duration(hours: 3)),
      );
      final now = start.add(const Duration(hours: 6));
      // Only the 3 hours before pausing count.
      expect(s.elapsed(now), const Duration(hours: 3));
    });

    test('progress is clamped to 0..1', () {
      final s = FastingSession(
        id: 'f',
        scheduleId: '12_12',
        targetHours: 12,
        startedAt: start,
      );
      expect(s.progress(start.add(const Duration(hours: 24))), 1.0);
      expect(s.progress(start), 0.0);
    });

    test('remaining never goes negative', () {
      final s = FastingSession(
        id: 'f',
        scheduleId: '14_10',
        targetHours: 14,
        startedAt: start,
      );
      expect(s.remaining(start.add(const Duration(hours: 20))), Duration.zero);
    });

    test('window opens at start + target + pause', () {
      final s = FastingSession(
        id: 'f',
        scheduleId: '16_8',
        targetHours: 16,
        startedAt: start,
        accumulatedPause: const Duration(minutes: 30),
      );
      expect(
        s.windowOpensAt(),
        start.add(const Duration(hours: 16, minutes: 30)),
      );
    });

    test('serialization round-trips through UTC', () {
      final s = FastingSession(
        id: 'f',
        scheduleId: '16_8',
        targetHours: 16,
        startedAt: start,
      );
      final restored = FastingSession.fromJson(s.toJson());
      expect(restored.startedAt.toUtc(), s.startedAt.toUtc());
      expect(restored.targetHours, 16);
    });

    test('only gentle schedules are offered', () {
      final maxHours = supportedFastingSchedules
          .map((s) => s.fastingHours)
          .reduce((a, b) => a > b ? a : b);
      expect(maxHours, lessThanOrEqualTo(16));
    });
  });

  group('Entitlements', () {
    test('monetization off gives everyone the free allowance', () {
      const e = Entitlements(
        tier: SubscriptionTier.free,
        flags: FeatureFlags(),
      );
      expect(e.aiQuestionsPerDay, 15);
      expect(e.advancedAnalytics, isTrue);
      expect(e.multipleSavedPrograms, isTrue);
    });

    test('account deletion and export are never gated', () {
      const e = Entitlements(
        tier: SubscriptionTier.free,
        flags: FeatureFlags(monetizationEnabled: true),
      );
      expect(e.canDeleteAccount, isTrue);
      expect(e.canExportData, isTrue);
    });

    test('premium gets the higher fair-use limit when monetization is on', () {
      const free = Entitlements(
        tier: SubscriptionTier.free,
        flags: FeatureFlags(monetizationEnabled: true),
      );
      const premium = Entitlements(
        tier: SubscriptionTier.premium,
        flags: FeatureFlags(monetizationEnabled: true),
      );
      expect(premium.aiQuestionsPerDay, greaterThan(free.aiQuestionsPerDay));
    });

    test('question gating respects the daily limit', () {
      const e = Entitlements(
        tier: SubscriptionTier.free,
        flags: FeatureFlags(freeAiQuestionsPerDay: 3),
      );
      expect(e.canAskAiQuestion(2), isTrue);
      expect(e.canAskAiQuestion(3), isFalse);
    });
  });
}
