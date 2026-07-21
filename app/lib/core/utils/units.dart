/// Unit conversion helpers.
///
/// All persisted values are metric (kg, cm, ml). Imperial values exist only
/// at the presentation boundary, so conversions happen in exactly one place.
abstract final class Units {
  static const double lbPerKg = 2.2046226218;
  static const double inPerCm = 0.3937007874;
  static const double flozPerMl = 0.0338140227;

  static double kgToLb(double kg) => kg * lbPerKg;
  static double lbToKg(double lb) => lb / lbPerKg;
  static double cmToIn(double cm) => cm * inPerCm;
  static double inToCm(double inches) => inches / inPerCm;
  static double mlToFloz(double ml) => ml * flozPerMl;
  static double flozToMl(double floz) => floz / flozPerMl;

  /// Splits centimeters into whole feet and remaining inches (rounded).
  static (int feet, int inches) cmToFeetInches(double cm) {
    final totalInches = cmToIn(cm).round();
    return (totalInches ~/ 12, totalInches % 12);
  }

  static double feetInchesToCm(int feet, int inches) =>
      inToCm((feet * 12 + inches).toDouble());

  static String formatWeight(double kg, {required bool metric}) {
    if (metric) return '${_trim(kg)} kg';
    return '${_trim(kgToLb(kg))} lb';
  }

  static String formatHeight(double cm, {required bool metric}) {
    if (metric) return '${cm.round()} cm';
    final (feet, inches) = cmToFeetInches(cm);
    return "$feet'$inches\"";
  }

  static String _trim(double v) {
    final rounded = (v * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);
  }
}
