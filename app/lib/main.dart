import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'core/config/env.dart';
import 'core/design/theme.dart';
import 'features/settings/application/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Abort immediately if a build combines production with the dev stub or is
  // missing required configuration (defense in depth; see AppEnvironment).
  AppEnvironment.guardProductionIntegrity();

  // Edge-to-edge Android UI (master requirement section 3).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const NutriGuideApp(),
    ),
  );
}

class NutriGuideApp extends ConsumerWidget {
  const NutriGuideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'NutriGuide AI',
      debugShowCheckedModeBanner: false,
      theme: NGTheme.light(),
      darkTheme: NGTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Guard against extreme system text scaling breaking layouts while
        // still honoring the user's accessibility preference (master req 14).
        final mq = MediaQuery.of(context);
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.6,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          child: child!,
        );
      },
    );
  }
}
