import 'package:flutter/material.dart';

/// Design tokens for NutriGuide AI.
///
/// Single source of truth for color, spacing, radius, elevation, motion and
/// typography. Widgets must consume these tokens (directly or through
/// [ThemeData]) instead of hard-coding values, so the visual language stays
/// consistent across every feature.
abstract final class NGColors {
  // Brand
  static const Color leaf = Color(0xFF3E7C52); // primary natural green
  static const Color leafDeep = Color(0xFF2C5A3B);
  static const Color leafSoft = Color(0xFFDCEBE0);
  static const Color gold = Color(0xFFB8933D); // restrained premium accent
  static const Color goldSoft = Color(0xFFF3EAD4);

  // Warm neutral surfaces (light)
  static const Color linen = Color(0xFFFAF7F2);
  static const Color parchment = Color(0xFFF2EDE4);
  static const Color sand = Color(0xFFE7E0D4);
  static const Color inkStrong = Color(0xFF25291F);
  static const Color inkMuted = Color(0xFF5B6153);

  // Dark surfaces
  static const Color nightBase = Color(0xFF171A15);
  static const Color nightRaised = Color(0xFF20241D);
  static const Color nightBorder = Color(0xFF363B31);
  static const Color mistStrong = Color(0xFFEDEBE4);
  static const Color mistMuted = Color(0xFFA9AC9F);

  // Semantic
  static const Color info = Color(0xFF33608D);
  static const Color success = Color(0xFF3E7C52);
  static const Color caution = Color(0xFF9A6B14);
  static const Color danger = Color(0xFFA33B2E);

  // Macro chart palette (accessible on light and dark surfaces)
  static const Color proteinChart = Color(0xFF52639C);
  static const Color carbChart = Color(0xFF3E7C52);
  static const Color fatChart = Color(0xFFB8933D);
  static const Color fiberChart = Color(0xFF7A5E9E);
  static const Color waterChart = Color(0xFF33608D);
}

abstract final class NGSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard horizontal screen padding.
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets card = EdgeInsets.all(lg);
}

abstract final class NGRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius control = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(sm));
}

abstract final class NGElevation {
  static const double none = 0;
  static const double raised = 1;
  static const double overlay = 3;
}

abstract final class NGMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve standard = Curves.easeOutCubic;

  /// Expressive curve for entrances and hero moments.
  static const Curve emphasized = Curves.easeOutQuart;

  /// Returns [Duration.zero] when the platform requests reduced motion, so
  /// animations collapse to instant transitions.
  static Duration of(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}

/// Minimum touch target per Material accessibility guidance.
abstract final class NGTouch {
  static const double minTarget = 48;
}

abstract final class NGTypography {
  static const String fontFamily = 'Roboto';

  static TextTheme textTheme(Color strong, Color muted) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: strong,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: strong,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: strong,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: strong,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: strong,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: strong,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: strong),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: strong),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: muted),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: strong,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: muted,
      ),
    );
  }
}
