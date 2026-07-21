# Google Play Compliance Map

This maps each relevant Google Play policy requirement to the product
behavior, the implementing file(s), the evidence, remaining manual action, and
status. **Google Play approval is never guaranteed;** this is preparation.

Legend — Status: ✅ implemented · 🟡 needs owner action · ⬜ pre-launch task.

| Requirement | Product behavior | Implementation | Evidence | Manual action | Status |
|---|---|---|---|---|---|
| Target API 36 | Build targets Android 16 / SDK 36 | `app/android/app/build.gradle.kts` (`targetSdk = 36`, `compileSdk = 36`) | Gradle config | Build AAB in CI | ✅ |
| Play App Signing | Upload key config; Play manages app signing | `build.gradle.kts` signingConfigs + `docs/SIGNED_BUILD.md` | Signing block | Create upload key, enroll in Play App Signing | 🟡 |
| Signed release AAB | Release build config with minify/shrink | `build.gradle.kts` release buildType | CI `flutter build appbundle` | Provide `key.properties` | ✅/🟡 |
| No unnecessary permissions | Only INTERNET, POST_NOTIFICATIONS, CAMERA (optional) | `app/android/app/src/main/AndroidManifest.xml` | Manifest + comments | — | ✅ |
| Accurate permission rationale | Camera requested at point of use; app works without it | `food_search_sheet.dart`, manifest comments | Runtime request flow | — | ✅ |
| Photo access via Photo Picker | No broad media permission; Android Photo Picker | Documented in manifest + `food_search_sheet.dart` | Manifest (no READ_MEDIA) | Wire picker when photo attach enabled | ✅ |
| Data Safety form | All data types mapped | `docs/DATA_SAFETY_MAPPING.md` | Mapping doc | Enter in Play Console | 🟡 |
| Health Apps declaration | Wellness, non-diagnostic; disclaimers throughout | `consent.dart`, disclaimers, `assets/legal/disclaimer.md` | In-app disclaimers | Complete Health declaration in Console | 🟡 |
| Public privacy policy | Draft provided; must be hosted | `assets/legal/privacy.md` | In-app + doc | Host at a public URL; add link in Console | 🟡 |
| In-app privacy policy | Accessible from Settings → Privacy & safety | `settings_screen.dart` → `/legal/privacy` | Settings screen | — | ✅ |
| Terms of Service | Draft provided | `assets/legal/terms.md` | In-app | Legal review + host | 🟡 |
| AI & wellness disclaimer | Shown onboarding, pre-chat, chat info, settings | `consent.dart`, `coach_info_screen.dart`, `onboarding_screen.dart` | Multiple screens | — | ✅ |
| In-app account deletion | Settings → Delete account (reauth) | `settings_screen.dart`, `account_service.dart`, backend `deleteMyAccount` | Delete flow | — | ✅ |
| Public account-deletion instructions | Draft provided | `assets/legal/account-deletion.md` | Doc | Host publicly, add URL | 🟡 |
| Data deletion (server-side) | Full Firestore + Auth deletion | `backend/functions/src/account/lifecycle.ts` | Cloud Function | Deploy | ✅ |
| Reviewer demo account | Instructions provided | `docs/RELEASE_CHECKLIST.md` | Checklist | Create reviewer account | 🟡 |
| Content rating | Guidance provided | `docs/STORE_LISTING.md` | Listing doc | Complete IARC questionnaire | 🟡 |
| Store listing copy | Short + full description drafted | `docs/STORE_LISTING.md` | Listing doc | Finalize + localize | 🟡 |
| Feature graphic / screenshots / icon | Specs provided | `docs/STORE_LISTING.md` | Listing doc | Produce assets | ⬜ |
| Ads / no personalized ads for health | No ads; no personalized advertising | No ad SDK in `pubspec.yaml` | Dependency list | — | ✅ |
| Financial features / subscriptions | Behind feature flag; Play Billing slot | `entitlements.dart` | Feature flag | Configure Play Billing if enabling | ✅ |
| Crash-free release validation | Crashlytics with health excluded | Setup in `docs/SETUP.md` | Config | Verify crash-free rate in testing | 🟡 |
| Pre-launch report | Robo/crawl checklist | `docs/RELEASE_CHECKLIST.md` | Checklist | Run in Console | ⬜ |
| Closed testing | Checklist provided | `docs/RELEASE_CHECKLIST.md` | Checklist | Run closed test track | ⬜ |
| Accessibility | WCAG-aligned, text scaling, reduced motion, contrast | `theme.dart`, `components.dart`, `main.dart` text-scale clamp | Widget tests | Manual TalkBack pass | ✅/🟡 |
| Developer verification / D-U-N-S | Org account checklist | `docs/RELEASE_CHECKLIST.md` | Checklist | Complete Play Console org verification | 🟡 |

## SDK / behavior consistency

The Data Safety declarations must match actual app + third-party SDK behavior.
Third-party SDKs in use: Firebase (Auth, Firestore, App Check, Crashlytics,
Messaging, Remote Config), and the backend-only AI provider. None collect data
for advertising. See `docs/DEPENDENCY_REGISTER.md`.
