import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_ai/core/utils/dates.dart';
import 'package:nutriguide_ai/core/utils/units.dart';

void main() {
  group('Units', () {
    test('kg/lb round-trip', () {
      expect(Units.lbToKg(Units.kgToLb(80)), closeTo(80, 1e-9));
    });

    test('cm to feet/inches', () {
      final (feet, inches) = Units.cmToFeetInches(180);
      // 180 cm ≈ 70.87 in → 5 ft 11 in
      expect(feet, 5);
      expect(inches, 11);
    });

    test('feet/inches to cm round-trip within rounding', () {
      final cm = Units.feetInchesToCm(5, 11);
      final (feet, inches) = Units.cmToFeetInches(cm);
      expect(feet, 5);
      expect(inches, 11);
    });

    test('formatWeight respects unit system', () {
      expect(Units.formatWeight(80, metric: true), '80 kg');
      expect(Units.formatWeight(80, metric: false), contains('lb'));
    });

    test('ml/fl oz round-trip', () {
      expect(Units.flozToMl(Units.mlToFloz(500)), closeTo(500, 1e-9));
    });
  });

  group('Dates', () {
    test('dayKey is stable and parseable', () {
      final d = DateTime(2026, 7, 21, 23, 59);
      expect(Dates.dayKey(d), '2026-07-21');
      expect(Dates.parseDayKey('2026-07-21').year, 2026);
    });

    test('late-night entry stays on the same local day', () {
      final almostMidnight = DateTime(2026, 7, 21, 23, 59, 59);
      expect(Dates.dayKey(almostMidnight), '2026-07-21');
    });

    test('lastDays returns oldest-first inclusive range', () {
      final days = Dates.lastDays(DateTime(2026, 7, 21), 3);
      expect(days, ['2026-07-19', '2026-07-20', '2026-07-21']);
    });

    test('startOfWeek returns Monday', () {
      // 2026-07-21 is a Tuesday.
      final monday = Dates.startOfWeek(DateTime(2026, 7, 21));
      expect(monday.weekday, DateTime.monday);
      expect(Dates.dayKey(monday), '2026-07-20');
    });

    test('friendly labels relative days', () {
      final now = DateTime(2026, 7, 21, 12);
      expect(Dates.friendly(DateTime(2026, 7, 21), now: now), 'Today');
      expect(Dates.friendly(DateTime(2026, 7, 20), now: now), 'Yesterday');
    });

    test('formatClock zero-pads', () {
      expect(
        Dates.formatClock(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
    });
  });
}
