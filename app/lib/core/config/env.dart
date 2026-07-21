/// Build-time application environment.
///
/// All values come from `--dart-define` so no secret or environment-specific
/// value is ever committed to source control. See docs/SETUP.md for the full
/// list and how each environment (dev / staging / prod) is configured.
///
/// SECURITY: only public client identifiers belong here (Firebase web API
/// keys are public identifiers protected by Firebase security rules and App
/// Check — see docs/THREAT_MODEL.md). Server secrets (AI provider keys,
/// service accounts) live exclusively in the backend's secret manager.
abstract final class AppEnvironment {
  /// 'dev' | 'staging' | 'prod'
  static const String flavor = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static bool get isProd => flavor == 'prod';
  static bool get isDev => flavor == 'dev';

  /// Firebase project configuration (public identifiers, not secrets).
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );

  /// Base URL of the NutriGuide backend (Cloud Functions / Cloud Run).
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
  );

  /// True when Firebase auth + sync are configured for this build.
  static bool get hasFirebase =>
      firebaseProjectId.isNotEmpty && firebaseApiKey.isNotEmpty;

  /// True when the AI Coach backend is configured for this build.
  static bool get hasBackend => backendBaseUrl.isNotEmpty;

  /// Development-only stub for auth and the AI Coach.
  ///
  /// The stub can NEVER run in a production build: the flag is ignored unless
  /// the flavor is 'dev'. Release pipelines set APP_ENV=prod (see
  /// .github/workflows/ci.yml), and [guardProductionIntegrity] aborts startup
  /// if a misconfigured build ever combines prod with the stub flag.
  static const bool _devStubRequested = bool.fromEnvironment(
    'USE_DEV_STUB',
    defaultValue: true,
  );

  static bool get useDevStub => isDev && _devStubRequested;

  /// Called during bootstrap; throws if an unsafe combination is detected.
  static void guardProductionIntegrity() {
    if (isProd && _devStubRequested) {
      throw StateError(
        'Invalid build configuration: USE_DEV_STUB must be false for '
        'production builds. Rebuild with --dart-define=USE_DEV_STUB=false.',
      );
    }
    if (isProd && !hasFirebase) {
      throw StateError(
        'Invalid build configuration: production builds require '
        'FIREBASE_PROJECT_ID and FIREBASE_API_KEY dart-defines.',
      );
    }
    if (isProd && !hasBackend) {
      throw StateError(
        'Invalid build configuration: production builds require '
        'BACKEND_BASE_URL for the AI Coach backend.',
      );
    }
  }
}
