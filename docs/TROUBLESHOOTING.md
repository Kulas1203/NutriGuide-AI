# Troubleshooting

## App

- **"Invalid build configuration" on startup** — a prod build has
  `USE_DEV_STUB=true` or is missing Firebase/backend defines. Rebuild with the
  correct `--dart-define`s (see `docs/SETUP.md`).
- **AI Coach says "could not be reached"** — backend unreachable or App Check
  failing. Your question is saved as a draft; retry when online. Check
  `BACKEND_BASE_URL` and App Check registration.
- **Analyzer errors after dependency changes** — run `flutter pub get`, then
  `flutter analyze`. The project targets zero analyzer issues.
- **Widget tests hang** — use the in-memory `LocalStore.inMemory()` harness and
  bounded `pump()`s, not `pumpAndSettle` (blinking cursor + spinners never
  settle). See `app/test/widget/harness.dart`.

## Android build

- **dl.google.com / maven.google.com blocked** — in restricted network
  environments the Android SDK/Gradle artifacts may be unreachable; build the
  AAB in CI (`.github/workflows/ci.yml`) where Google endpoints are allowed.
- **`compileSdk 36` not found** — install the API 36 platform:
  `sdkmanager "platforms;android-36" "build-tools;36.0.0"`.

## Backend

- **`enforceAppCheck` type error** — only valid on `onCall`; `onRequest`
  verifies App Check manually via `X-Firebase-AppCheck` (see `index.ts`).
- **Deploy fails on secrets** — set `ANTHROPIC_API_KEY` via
  `firebase functions:secrets:set` before deploy.

## AI evals

- **"Could not load the compiled safety classifier"** — build first:
  `(cd backend/functions && npm run build)`.
