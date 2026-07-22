# Data Safety Mapping

Source of truth for the Google Play **Data Safety** form. Every data type the
app collects, shares, processes, encrypts, optionally provides, and can delete.
Keep this in sync with actual app and SDK behavior before each release.

## Global statements

- **Encryption in transit:** Yes (HTTPS/TLS for all Firebase + backend calls).
- **Encryption at rest:** Yes (Firebase-managed; device data in app-private
  storage; auth tokens in `flutter_secure_storage`).
- **Data deletion:** Users can request deletion in-app (Settings → Delete
  account) and via a public URL. Server-side deletion removes Firestore data
  and the Auth account.
- **Data sold:** No.
- **Data used for advertising / personalized ads:** No.
- **AI model training on private conversations:** No, not without separate,
  explicit, informed opt-in.
- **Independent security review:** Recommended before launch (not yet done).

## Data types

| Data type | Collected | Shared | Purpose | Optional | Encrypted in transit | Deletable |
|---|---|---|---|---|---|---|
| Email address | Yes | Processors only (Firebase Auth) | Account, auth | No | Yes | Yes |
| Name / preferred display name | Yes | No | Personalization | No (name required) | Yes | Yes |
| Age (18+ confirmation, age value) | Yes | No | Eligibility, calorie estimate | No | Yes | Yes |
| Approximate country | Yes | No | Localization, food data | Yes | Yes | Yes |
| Health & fitness — body metrics (height, weight, waist) | Yes | No | Targets, progress | Weight optional to hide | Yes | Yes |
| Health & fitness — dietary preferences, allergies | Yes | No | Meal plans, safety filtering | Allergies optional | Yes | Yes |
| Health & fitness — health considerations (flags), medications timing note | Yes | No | Safety guidance restriction | Yes (clearly optional) | Yes | Yes |
| Health & fitness — food diary, fasting, water logs | Yes | No | Tracking | Yes | Yes | Yes |
| App activity — meal plans, habits, ratings | Yes | No | Feature function | Yes | Yes | Yes |
| Messages — AI Coach conversations | Yes (if history enabled) | Processors only (AI provider, to answer) | Provide the coach answer | Yes (can disable history) | Yes | Yes |
| Photos (optional food photos) | Only if user attaches | No | User's own records | Yes | Yes | Yes |
| Diagnostics — crash logs | Yes | Processors only (Crashlytics) | Stability | Yes (opt-out) | Yes | N/A (health excluded) |
| Device / App Check tokens | Yes | Processors only (Google) | Abuse prevention | No | Yes | N/A |

## What is NOT collected

Precise location, contacts, SMS/call logs, browsing history, microphone audio,
broad media/photo library, financial/payment info (unless subscriptions are
enabled, then handled entirely by Google Play Billing — the app never sees card
data).

## Processors (sub-processors)

- Google Firebase (Auth, Firestore, Storage, App Check, Crashlytics, Cloud
  Messaging, Remote Config) — infrastructure.
- Configured AI provider (DeepSeek via the backend) — generates coach
  answers from the user's question; governed by the AI Transparency Notice.
  ACTION REQUIRED before launch: confirm DeepSeek's data-residency, retention
  and training-use terms and reflect them in the Privacy Policy and the Play
  Data Safety form. Only the user's typed question and non-identifying context
  are sent (no account identifiers); requests are not used to expose secrets.

## Notifications & lock screen

Private-notification mode (default on) uses generic text so no diet or health
detail appears on the lock screen.
