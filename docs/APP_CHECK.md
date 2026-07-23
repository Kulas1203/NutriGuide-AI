# Firebase App Check

The AI Coach backend (`coachAsk`) rejects any request that does not carry a
valid App Check token in the `X-Firebase-AppCheck` header. This blocks
automated abuse of the paid AI provider while letting genuine app installs
through. This document describes how the client mints that token.

## Client seam

The app talks to Firebase over REST and ships **no** Firebase SDK, so App
Check token minting is expressed as a small interface,
`AppCheckService` (`app/lib/features/coach/data/app_check_service.dart`):

- `NoopAppCheckService` — no token. Used by dev builds, which route the Coach
  to the offline `DevCoachService` and never reach the backend.
- `DebugAppCheckService` — takes an App Check *debug token* supplied at build
  time via `--dart-define=APP_CHECK_DEBUG_TOKEN=...` and **exchanges** it for a
  real, short-lived App Check token through Firebase's public
  `exchangeDebugToken` endpoint (the raw debug token is not itself a valid
  App Check token — the native SDK performs the same exchange internally). The
  exchange needs `FIREBASE_APP_ID` and `FIREBASE_PROJECT_NUMBER` in addition to
  the debug token and web API key.

`BackendCoachService` reads the token and attaches the header on every Coach
request; `defaultAppCheckService()` selects the implementation from the build
config (`AppEnvironment.appCheckDebugToken`).

## Verifying the enforced backend now (dev / staging, incl. Chrome/web)

You can exercise the real App Check-enforced backend from the web or dev
build without any native SDK, using a **debug token**:

1. Firebase console → **App Check** → **Apps** → your app → **⋮ →
   Manage debug tokens** → **Add debug token**. Give it a name (e.g.
   `local-web-dev`) and copy the generated UUID.
2. Put it — plus the app id and project number — in your (git-ignored)
   config, e.g. `app/config/dev.json`:
   ```json
   "FIREBASE_APP_ID": "1:461669117225:web:...",
   "FIREBASE_PROJECT_NUMBER": "461669117225",
   "APP_CHECK_DEBUG_TOKEN": "the-uuid-from-the-console"
   ```
   (App id and project number are on the Firebase console's Project settings →
   General page; the debug token must be registered under that same app.)
3. Run with the backend wired up:
   ```bash
   flutter run -d chrome --dart-define-from-file=config/dev.json
   ```
   Coach requests now carry `X-Firebase-AppCheck` and the backend accepts
   them. Remove the token (or leave it blank) to confirm the backend returns
   `401 App Check required` without it.

Debug tokens are per-environment identifiers registered in the console, not
cryptographic secrets — but still keep them out of source control (they live
only in the git-ignored `config/*.json`).

## Production Android (Play Integrity)

A shipped Android release must present a **real** Play Integrity attestation,
not a debug token. That token can only be produced by the native
`firebase_app_check` plugin. At release time:

1. Firebase console → **App Check** → register the Android app with the
   **Play Integrity** provider. Set enforcement to **Enforced** for
   Cloud Functions once the release is verified.
2. Add the plugin and a real `FirebaseAppCheckService` behind the existing
   `AppCheckService` interface:
   ```yaml
   # pubspec.yaml
   firebase_core: ^<latest>
   firebase_app_check: ^<latest>
   ```
   ```dart
   // real implementation, wired in defaultAppCheckService() for prod Android
   class FirebaseAppCheckService implements AppCheckService {
     @override
     Future<String?> token() =>
         FirebaseAppCheck.instance.getToken(); // Play Integrity
   }
   ```
   This requires the standard native Firebase setup (`google-services.json`,
   the Google Services Gradle plugin) for the release flavor only. No caller
   changes: `BackendCoachService` keeps using the interface.
3. Keep enforcement **unenforced/monitor** until real-device installs are
   confirmed passing, then switch to **enforced**.

Until the native provider is wired, production Coach calls will 401 by design
— the backend is fail-closed. Ship the native App Check integration together
with enabling the backend in production (see docs/SETUP.md §2–3).
