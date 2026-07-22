import '../../../core/config/env.dart';

/// Firebase App Check boundary.
///
/// The backend `coachAsk` endpoint rejects any request that does not carry a
/// valid App Check token in the `X-Firebase-AppCheck` header (see
/// backend/functions/src/index.ts). This service mints that token on the
/// client so legitimate app installs can reach the AI Coach while automated
/// abuse is blocked.
///
/// The app deliberately talks to Firebase over REST and ships no Firebase
/// SDK, so token minting is expressed as a small seam:
///
///  * [NoopAppCheckService] — no token (dev builds / App Check not yet
///    configured). The backend will refuse Coach calls, which is correct:
///    dev builds use [DevCoachService] and never hit the backend.
///  * [DebugAppCheckService] — returns a debug token supplied at build time
///    via `--dart-define=APP_CHECK_DEBUG_TOKEN=...`. Debug tokens are
///    registered in the Firebase console (App Check → Apps → Manage debug
///    tokens) and are valid in the `X-Firebase-AppCheck` header from any
///    transport, so they let staging/dev verify the full App Check-enforced
///    Coach flow (including from the web/Chrome build) without the native SDK.
///
/// For a signed Android production release, a real Play Integrity token must
/// be minted by the native `firebase_app_check` plugin. That path is added at
/// release time (see docs/APP_CHECK.md); it plugs in behind this same
/// interface without touching callers.
abstract class AppCheckService {
  /// A fresh App Check token, or null when App Check is not configured for
  /// this build (in which case backend Coach calls are expected to fail).
  Future<String?> token();
}

/// No-op implementation: never returns a token. Used in dev builds and any
/// build without App Check configured.
class NoopAppCheckService implements AppCheckService {
  const NoopAppCheckService();

  @override
  Future<String?> token() async => null;
}

/// Returns a Firebase App Check debug token supplied at build time.
///
/// The token is a public-per-environment identifier registered in the
/// Firebase console, not a secret in the cryptographic sense, but it is still
/// provided via `--dart-define` (never committed) and only used for
/// dev/staging verification.
class DebugAppCheckService implements AppCheckService {
  const DebugAppCheckService(this._debugToken);

  final String _debugToken;

  @override
  Future<String?> token() async =>
      _debugToken.isEmpty ? null : _debugToken;
}

/// Selects the App Check implementation for the current build.
///
/// A debug token, when provided, is used regardless of flavor so staging can
/// exercise the enforced backend. Otherwise no token is sent (dev builds do
/// not reach the backend; a production Android build wires the native
/// Play Integrity provider — see docs/APP_CHECK.md).
AppCheckService defaultAppCheckService() {
  final debugToken = AppEnvironment.appCheckDebugToken;
  if (debugToken.isNotEmpty) {
    return DebugAppCheckService(debugToken);
  }
  return const NoopAppCheckService();
}
