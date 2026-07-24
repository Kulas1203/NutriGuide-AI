import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the Material 3 themes for NutriGuide AI from the design tokens.
abstract final class NGTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: NGColors.leaf,
          brightness: Brightness.light,
        ).copyWith(
          primary: NGColors.leaf,
          onPrimary: Colors.white,
          primaryContainer: NGColors.leafSoft,
          onPrimaryContainer: NGColors.leafDeep,
          secondary: NGColors.gold,
          onSecondary: Colors.white,
          secondaryContainer: NGColors.goldSoft,
          onSecondaryContainer: const Color(0xFF5C4A1E),
          surface: NGColors.linen,
          onSurface: NGColors.inkStrong,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF6F2EA),
          surfaceContainer: NGColors.parchment,
          surfaceContainerHigh: const Color(0xFFEDE7DB),
          surfaceContainerHighest: NGColors.sand,
          outline: const Color(0xFF847F73),
          outlineVariant: const Color(0xFFD5CEC0),
          error: NGColors.danger,
        );
    return _base(scheme, NGColors.inkStrong, NGColors.inkMuted);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: NGColors.leaf,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF8FC49E),
          onPrimary: const Color(0xFF12301C),
          primaryContainer: NGColors.leafDeep,
          onPrimaryContainer: NGColors.leafSoft,
          secondary: const Color(0xFFD6BC72),
          onSecondary: const Color(0xFF3B2F0B),
          secondaryContainer: const Color(0xFF57451A),
          onSecondaryContainer: NGColors.goldSoft,
          surface: NGColors.nightBase,
          onSurface: NGColors.mistStrong,
          surfaceContainerLowest: const Color(0xFF121510),
          surfaceContainerLow: const Color(0xFF1B1E18),
          surfaceContainer: NGColors.nightRaised,
          surfaceContainerHigh: const Color(0xFF262B22),
          surfaceContainerHighest: const Color(0xFF2D3329),
          outline: const Color(0xFF8D9184),
          outlineVariant: NGColors.nightBorder,
          error: const Color(0xFFE5897C),
        );
    return _base(scheme, NGColors.mistStrong, NGColors.mistMuted);
  }

  static ThemeData _base(ColorScheme scheme, Color strong, Color muted) {
    final textTheme = NGTypography.textTheme(strong, muted);
    final dark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      // Modern M3 forward transition + Android predictive-back support.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: NGElevation.none,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: NGElevation.raised,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        // Hairline border keeps cards crisply defined on dark surfaces where
        // shadows are invisible.
        shape: RoundedRectangleBorder(
          borderRadius: NGRadius.card,
          side: dark
              ? BorderSide(color: scheme.outlineVariant, width: 0.8)
              : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, NGTouch.minTarget),
          shape: const RoundedRectangleBorder(borderRadius: NGRadius.control),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, NGTouch.minTarget),
          shape: const RoundedRectangleBorder(borderRadius: NGRadius.control),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, NGTouch.minTarget),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: NGRadius.control,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: NGRadius.control,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: NGRadius.control,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: NGRadius.control,
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NGSpacing.lg,
          vertical: NGSpacing.md,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: NGRadius.chip),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelLarge,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: NGRadius.control),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(NGRadius.xl)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(NGRadius.xl),
          ),
        ),
        showDragHandle: true,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        minVerticalPadding: NGSpacing.md,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
