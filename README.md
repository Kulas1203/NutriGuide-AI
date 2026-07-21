# NutriGuide AI

Personalized diet, nutrition, meal-planning, food-tracking, fasting, and
wellness Android app with an evidence-grounded **AI Nutrition Coach**.

> NutriGuide AI provides educational nutrition information, meal-planning
> assistance, food tracking, and general wellness guidance. It does not
> diagnose, treat, cure, or prevent medical conditions and is not a substitute
> for advice from a physician or registered dietitian. Designed for adults
> (18+).

## Highlights

- **Flutter (Android), Material 3**, edge-to-edge, dark/light, adaptive layouts,
  accessible, clean feature-first architecture, Riverpod + GoRouter.
- **18 evidence-based diet programs** with comparison, transparent
  Mifflin–St Jeor calorie/macro targets (with a safety floor), a deterministic
  meal-plan engine with server-mirrored validation, fast food logging with
  nutrition provenance, gentle fasting (12:12–16:8), and supportive progress
  tracking.
- **AI Nutrition Coach** through a secure backend: layered client + server
  safety classifier, structured answers with sources and a confidence level,
  streaming, graceful failure, and full conversation controls.
- **Privacy-first**: local-first storage, data export, in-app account deletion,
  AI-history toggle, private notifications. No data selling, no ads, no
  training on private conversations without opt-in.
- **Secure backend**: Firebase Auth + Firestore (per-user rules) + Cloud
  Functions (AI orchestration, plan validation, export, deletion), App Check,
  rate limiting, audit logs without health data.

## Repository layout

```
app/                Flutter application (lib/, test/, android/, assets/)
backend/            Firebase: functions/ (TS), firestore/ rules+indexes, storage.rules
ai_evals/           Versioned AI safety evaluation dataset + runner
data/               Local-food CSV schema + import workflow
tool/               Seed-data generator (validated USDA + estimated dishes)
docs/               Architecture, setup, threat model, compliance, release, etc.
.github/workflows/  CI (analyze, test, build AAB, backend tests, AI eval gate)
```

## Quick start (development, no credentials needed)

```bash
cd app && flutter pub get && flutter run   # runs with local dev stubs
```

## Tests

```bash
cd app && flutter analyze && flutter test        # 0 issues, 91 tests
cd backend/functions && npm install && npm run build && npm test
node ai_evals/run_safety_evals.mjs               # 22/22 safety cases
```

## Documentation

Start with [`docs/SETUP.md`](docs/SETUP.md) and
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). Compliance and release:
[`docs/PLAY_STORE_COMPLIANCE.md`](docs/PLAY_STORE_COMPLIANCE.md),
[`docs/DATA_SAFETY_MAPPING.md`](docs/DATA_SAFETY_MAPPING.md),
[`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md),
[`docs/SIGNED_BUILD.md`](docs/SIGNED_BUILD.md). Security:
[`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md).

Legal drafts (in `app/assets/legal/`, also viewable in-app) are **drafts
requiring review by qualified legal counsel** and use clearly labeled
placeholders for owner-specific details.

## Enable git hooks

```bash
git config core.hooksPath .githooks
```

## License

See [LICENSE](LICENSE).
