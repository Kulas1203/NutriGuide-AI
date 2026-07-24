# Changelog

All notable changes to NutriGuide AI. Format: Keep a Changelog; SemVer.

## [1.0.0] — Unreleased (initial development build)

### Added
- Flutter Android app (Material 3, edge-to-edge, dark/light, adaptive) with
  clean feature-first architecture and Riverpod (Notifier) state management.
- Onboarding with age (18+) confirmation and multi-place disclaimer consent.
- 18 evidence-grounded diet programs with up-to-three comparison.
- Transparent Mifflin–St Jeor calorie/macro engine with safety floor and
  target-date sanity checks (unit-tested).
- Deterministic meal-plan generator with server-mirrored validation, grocery
  lists, swaps, locks, servings, ratings.
- Fast food diary (search, recent, quick add, copy-yesterday, provenance
  badges), water tracking, offline-first storage.
- Fasting timer (12:12–16:8) with immediate stop and safety messaging.
- Progress tracking (weight trend, habits) with supportive language.
- AI Nutrition Coach with client + authoritative server safety layers,
  structured answers (sources, confidence, referral), streaming, graceful
  failure with restorable draft, and history controls.
- Secure backend: Cloud Functions (AI orchestration, plan validation, export,
  deletion), Firestore rules + indexes, rate limiting, audit logs without
  health data.
- Privacy controls: data export, in-app account deletion (reauth), AI history
  toggle, private notifications.
- Legal/policy drafts, Play Store compliance + data-safety mapping, threat
  model, dependency register, architecture docs with Mermaid diagrams.
- Automated tests: 91 Flutter tests, 11 backend tests, Firestore rules tests,
  22-case AI safety evaluation suite. GitHub Actions CI.

### Security
- No secrets in the app; production build cannot use dev stubs.
- Least-privilege permissions (INTERNET, opt-in notifications, optional
  camera); Photo Picker instead of broad media access.
