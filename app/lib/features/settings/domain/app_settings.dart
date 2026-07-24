import 'package:flutter/material.dart';

/// App-wide preferences persisted locally. Notification categories are all
/// independently controllable and off by default until the user opts in
/// (master requirement §17).
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.metricUnits = true,
    this.privateNotifications = true,
    this.mealReminders = false,
    this.waterReminders = false,
    this.fastingReminders = false,
    this.groceryReminders = false,
    this.weeklySummary = false,
    this.habitReminders = false,
  });

  final ThemeMode themeMode;
  final bool metricUnits;

  /// When true, notification bodies use generic text with no diet/health
  /// details on the lock screen (master requirement §15).
  final bool privateNotifications;

  final bool mealReminders;
  final bool waterReminders;
  final bool fastingReminders;
  final bool groceryReminders;
  final bool weeklySummary;
  final bool habitReminders;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? metricUnits,
    bool? privateNotifications,
    bool? mealReminders,
    bool? waterReminders,
    bool? fastingReminders,
    bool? groceryReminders,
    bool? weeklySummary,
    bool? habitReminders,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    metricUnits: metricUnits ?? this.metricUnits,
    privateNotifications: privateNotifications ?? this.privateNotifications,
    mealReminders: mealReminders ?? this.mealReminders,
    waterReminders: waterReminders ?? this.waterReminders,
    fastingReminders: fastingReminders ?? this.fastingReminders,
    groceryReminders: groceryReminders ?? this.groceryReminders,
    weeklySummary: weeklySummary ?? this.weeklySummary,
    habitReminders: habitReminders ?? this.habitReminders,
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'metricUnits': metricUnits,
    'privateNotifications': privateNotifications,
    'mealReminders': mealReminders,
    'waterReminders': waterReminders,
    'fastingReminders': fastingReminders,
    'groceryReminders': groceryReminders,
    'weeklySummary': weeklySummary,
    'habitReminders': habitReminders,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode: ThemeMode.values.byName(
      json['themeMode'] as String? ?? 'system',
    ),
    metricUnits: json['metricUnits'] as bool? ?? true,
    privateNotifications: json['privateNotifications'] as bool? ?? true,
    mealReminders: json['mealReminders'] as bool? ?? false,
    waterReminders: json['waterReminders'] as bool? ?? false,
    fastingReminders: json['fastingReminders'] as bool? ?? false,
    groceryReminders: json['groceryReminders'] as bool? ?? false,
    weeklySummary: json['weeklySummary'] as bool? ?? false,
    habitReminders: json['habitReminders'] as bool? ?? false,
  );
}
