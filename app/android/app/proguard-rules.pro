# NutriGuide AI ProGuard rules.
# Flutter's Gradle plugin supplies the core Flutter keep rules; these cover the
# plugins we ship. Keep rules are intentionally minimal.

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# Play Core (used by Flutter deferred components / split installs if enabled)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep annotations used by reflection-free plugins.
-keepattributes *Annotation*
