import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/session_controller.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/coach/presentation/coach_info_screen.dart';
import '../features/coach/presentation/coach_screen.dart';
import '../features/diets/presentation/diet_detail_screen.dart';
import '../features/diets/presentation/diet_discovery_screen.dart';
import '../features/fasting/presentation/fasting_screen.dart';
import '../features/home/presentation/app_shell.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/legal/legal_document_screen.dart';
import '../features/logging/presentation/log_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/planner/presentation/grocery_screen.dart';
import '../features/planner/presentation/planner_screen.dart';
import '../features/profile/application/profile_controller.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/targets/presentation/targets_screen.dart';

/// Bridges Riverpod state changes to GoRouter refreshes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
    ref.listen(profileControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final profileState = ref.read(profileControllerProvider);
      final loc = state.matchedLocation;

      if (session.status == SessionStatus.loading || profileState.loading) {
        return loc == '/splash' ? null : '/splash';
      }
      final loggedIn = session.status == SessionStatus.signedIn;
      if (!loggedIn) {
        return loc == '/auth' ? null : '/auth';
      }
      // Logged in but no profile yet -> onboarding.
      if (!profileState.hasProfile) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      // Logged in with profile; keep them out of auth/splash/onboarding.
      if (loc == '/auth' || loc == '/splash' || loc == '/onboarding') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      GoRoute(path: '/splash', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/plan', builder: (_, _) => const PlannerScreen()),
          GoRoute(path: '/log', builder: (_, _) => const LogScreen()),
          GoRoute(path: '/coach', builder: (_, _) => const CoachScreen()),
          GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
        ],
      ),
      GoRoute(path: '/diets', builder: (_, _) => const DietDiscoveryScreen()),
      GoRoute(
        path: '/diets/:id',
        builder: (_, state) =>
            DietDetailScreen(dietId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/targets', builder: (_, _) => const TargetsScreen()),
      GoRoute(path: '/fasting', builder: (_, _) => const FastingScreen()),
      GoRoute(path: '/grocery', builder: (_, _) => const GroceryScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/coach/info', builder: (_, _) => const CoachInfoScreen()),
      GoRoute(
        path: '/legal/:doc',
        builder: (_, state) =>
            LegalDocumentScreen(document: state.pathParameters['doc']!),
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, size: 56, color: scheme.primary),
            const SizedBox(height: 20),
            Text(
              'NutriGuide AI',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
