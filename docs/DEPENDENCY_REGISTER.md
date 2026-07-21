# Dependency Register

Why each major dependency is necessary, its role, and review notes. Review
criteria per package: maintenance status, latest stable, Android API 36
compatibility, privacy implications, required permissions, license, known
security concerns. Re-review before adding or upgrading.

## Flutter app (`app/pubspec.yaml`)

| Package | Purpose | Notes |
|---|---|---|
| `flutter_riverpod` | Predictable state management (Notifier/NotifierProvider) | Actively maintained; no permissions; MIT |
| `go_router` | Declarative navigation + guards | Flutter-team package; MIT |
| `dio` | HTTP client for Firebase REST + backend streaming | Maintained; supports streamed responses; no extra permissions; MIT |
| `shared_preferences` | Small key/value prefs (dev auth store, flags) | Flutter-team; MIT |
| `path_provider` | App documents directory for `LocalStore` | Flutter-team; MIT |
| `intl` | Date/number formatting | Dart-team; pinned to 0.20.2 by `flutter_localizations`; BSD |
| `uuid` | Stable ids for records (dedupe on sync) | Maintained; MIT |
| `fl_chart` | Weight/progress charts | Maintained; no permissions; MIT/BSD |
| `connectivity_plus` | Online/offline detection for cached-data notices | Maintained (fluttercommunity); no location permission used; BSD |
| `flutter_secure_storage` | Encrypted storage for auth refresh token | Maintained; sets `minSdk 24`; MIT |
| `package_info_plus` | App version display in Settings | Maintained; MIT |
| `flutter_local_notifications` | Optional, granular reminders | Maintained; notifications only when user opts in; BSD |
| `crypto` | Password hashing for the dev-only local auth stub | Dart-team; MIT |
| `flutter_lints` (dev) | Lint rules (with strict analysis options) | Flutter-team; BSD |

### Deliberately NOT used

- No ad SDKs, analytics-for-ads SDKs, or trackers.
- No broad-permission packages (contacts, SMS, precise location, media
  library). Photo attachment uses the Android Photo Picker.
- No abandoned/unmaintained packages.

## Backend (`backend/functions/package.json`)

| Package | Purpose | Notes |
|---|---|---|
| `firebase-functions` | Cloud Functions runtime (v2) | Google; Apache-2.0 |
| `firebase-admin` | Admin SDK for privileged Firestore/Auth ops | Google; Apache-2.0 |
| `@anthropic-ai/sdk` | AI provider client (server-only key) | Vendor SDK; used behind the provider abstraction so it can be swapped |
| `typescript`, `vitest`, `@types/node` (dev) | Build + tests | Maintained; MIT |
| `@firebase/rules-unit-testing` (dev) | Firestore rules tests | Google; Apache-2.0 |

## Android / build

- `compileSdk`/`targetSdk` **36**, `minSdk` **24** (driven by
  `flutter_secure_storage`; covers the large majority of active devices),
  JDK 17, R8 minify + resource shrink for release.
- **Core library desugaring** enabled (`desugar_jdk_libs:2.1.4`) because
  `flutter_local_notifications` uses `java.time` APIs that need backporting
  below API 26.
