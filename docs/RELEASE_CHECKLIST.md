# Release Checklist

Versioning: SemVer `version: MAJOR.MINOR.PATCH+BUILD` in `app/pubspec.yaml`.
Increment the build number every upload. Tag releases `vMAJOR.MINOR.PATCH`.

## Pre-build

- [ ] `flutter analyze` → 0 issues.
- [ ] `flutter test` → all pass.
- [ ] `cd backend/functions && npm run build && npm test` → pass.
- [ ] `node ai_evals/run_safety_evals.mjs` → 22/22 pass.
- [ ] Content review checklist signed off by a registered dietitian.
- [ ] Legal drafts reviewed by qualified counsel; `{{PLACEHOLDER}}`s replaced.
- [ ] Privacy policy + account-deletion instructions hosted at public URLs.
- [ ] Bump `version`/build number; update `docs/CHANGELOG.md`.

## Backend

- [ ] Secrets set (`ANTHROPIC_API_KEY`); `MODEL_ID` pinned to an evaluated model.
- [ ] `firebase deploy --only firestore:rules,firestore:indexes,functions,storage`.
- [ ] App Check enforced; Play Integrity provider configured.
- [ ] Firestore TTL policy on `rateLimits.expireAt`.
- [ ] Scheduled Firestore backups enabled.

## Build (signed AAB)

- [ ] Provide `app/android/key.properties` (or CI signing secrets).
- [ ] `flutter build appbundle --release` with prod `--dart-define`s
      (`APP_ENV=prod`, `USE_DEV_STUB=false`, Firebase + backend values).
- [ ] Confirm AAB at `app/build/app/outputs/bundle/release/app-release.aab`.
- [ ] Confirm `targetSdk=36`, no debug packages, no test credentials.

## Play Console

- [ ] Enroll in Play App Signing (first upload).
- [ ] Complete **Data Safety** form from `docs/DATA_SAFETY_MAPPING.md`.
- [ ] Complete **Health Apps** declaration; attach disclaimer.
- [ ] Complete content-rating (IARC) questionnaire.
- [ ] Store listing from `docs/STORE_LISTING.md`; upload icon, feature graphic,
      phone + tablet/foldable screenshots.
- [ ] Add support email and privacy policy URL.
- [ ] Provide **reviewer access**: create a demo account
      (email/password) with a completed profile and sample data; put
      credentials + a short walkthrough in the review notes. If the AI Coach
      needs the backend, ensure the demo account can reach staging/prod.
- [ ] Organization developer-account verification (D-U-N-S where applicable).

## Testing tracks

- [ ] Internal testing smoke pass.
- [ ] Closed testing track with real testers; collect crash-free rate.
- [ ] Run the **Pre-launch report** (Robo test); triage findings.
- [ ] Accessibility pass with TalkBack + large text + dark mode.
- [ ] Verify offline behavior, account deletion, and data export on-device.

## Post-submission

- [ ] Do not promise approval timelines.
- [ ] Monitor Crashlytics, function errors, and rate-limit anomalies.
- [ ] Have a rollback plan (previous AAB + previous functions revision).
