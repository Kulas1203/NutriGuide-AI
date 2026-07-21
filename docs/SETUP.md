# Setup Guide

## Prerequisites

- Flutter stable (3.44+), Dart 3.12+
- Android SDK with platform + build tools for **API 36**, JDK 17
- Node.js 20 (for the backend and tooling)
- A Firebase project (three recommended: dev / staging / prod)
- Firebase CLI (`npm i -g firebase-tools`) for backend deploys

## 1. App (local / development)

The app runs out of the box in **development mode** with local stubs — no
Firebase or AI credentials required:

```bash
cd app
flutter pub get
flutter run                 # APP_ENV defaults to dev, USE_DEV_STUB=true
```

In dev mode:
- Auth is a local, on-device stub (`DevLocalAuthService`).
- The AI Coach answers from a small offline knowledge base
  (`DevCoachService`) and clearly labels replies as "development stub".

Regenerate the bundled food/recipe datasets after editing
`tool/generate_seed_data.mjs`:

```bash
node tool/generate_seed_data.mjs   # writes app/assets/data/*.json
```

## 2. Firebase backend

```bash
cd backend
cp .firebaserc .firebaserc            # then fill in real project ids
firebase use dev

# Configure secrets (never commit these)
cd functions
cp .env.example .env                  # fill non-secret params (MODEL_ID, etc.)
firebase functions:secrets:set ANTHROPIC_API_KEY

npm install
npm run build
npm test                              # safety + plan-validation unit tests

# Deploy rules, indexes and functions
cd ..
firebase deploy --only firestore:rules,firestore:indexes,functions,storage
```

Enable in the Firebase console: **Authentication** (Email/Password),
**App Check** (Play Integrity provider for Android), **Remote Config** (for
feature flags), **Crashlytics** (with health data excluded from logs), and a
**Firestore TTL policy** on `rateLimits.expireAt`.

## 3. Wiring the app to a real backend (staging / prod)

Provide build-time configuration via `--dart-define` (see `app/.env.example`
for the variable names). Firebase web API keys are public identifiers, not
secrets.

```bash
flutter build appbundle \
  --dart-define=APP_ENV=prod \
  --dart-define=USE_DEV_STUB=false \
  --dart-define=FIREBASE_PROJECT_ID=your-prod-project \
  --dart-define=FIREBASE_API_KEY=your-public-web-api-key \
  --dart-define=BACKEND_BASE_URL=https://<region>-<project>.cloudfunctions.net
```

`AppEnvironment.guardProductionIntegrity()` aborts startup if a prod build is
missing config or still has the dev stub enabled.

## 4. AI grounding knowledge base (optional but recommended)

Populate the reviewed `/reference/**` Firestore collection with versioned
diet content, USDA FoodData Central summaries, approved public-health
references, and the curated local-food dataset. Each item must carry a source,
title, date, review status, last-reviewed date, applicable population and
version. Wire `setKnowledgeStore` in `backend/functions/src/index.ts` to query
it. Until populated, the coach honestly states uncertainty rather than
fabricating sources.

## 5. AI evaluations (safety gate)

Before enabling a new model or safety/prompt version:

```bash
(cd backend/functions && npm run build)
node ai_evals/run_safety_evals.mjs      # must pass 22/22
```

Full model-answer evaluations run against a staging backend: send each
`ai_evals/dataset.v1.json` case to `coachAsk` and confirm the answer matches
the case's `expectedBehavior` (no fabricated citations, correct referrals,
urgent-care-first for emergencies). Record results before promoting a model.

## 6. Tests

```bash
cd app && flutter test          # 91 unit + widget tests
cd backend/functions && npm test   # safety + plan validation
# Firestore rules (needs the emulator):
firebase emulators:exec --only firestore \
  "node --test backend/firestore/rules.test.js"
```

## Troubleshooting

See `docs/TROUBLESHOOTING.md`.
