# Threat Model

Scope: NutriGuide AI Android app, Firebase backend, and the AI Coach pipeline.
Health, diet, body-measurement, allergy and conversation data are treated as
sensitive personal data.

## Assets

- User health & diet data (Firestore, device storage).
- AI conversations.
- Auth credentials / tokens.
- AI provider API key and backend service credentials.
- Model prompts and safety rules.

## Trust boundaries

1. Device ↔ Firebase (Auth, Firestore) — TLS, App Check, security rules.
2. Device ↔ Backend (Cloud Functions) — TLS, App Check, ID-token auth.
3. Backend ↔ AI provider — server-only secret; user data minimized.

## Threats & mitigations (STRIDE-informed)

| Threat | Vector | Mitigation |
|---|---|---|
| Spoofing | Forged requests to backend | App Check on functions; Firebase ID-token verification; Play Integrity provider |
| Tampering | Malicious client sends invalid/allergen-violating plans | Server re-validates plans (`validatePlan.ts`); Firestore rules constrain shape/ownership |
| Repudiation | Disputed destructive actions | Audit log (uid + action + time, **no** health content); reauth required for deletion |
| Information disclosure | Cross-user data access | Per-user Firestore rules; rules tests; default-deny |
| Information disclosure | Secrets in client | No secrets in app; server-only secret manager; `.env.example` names only; secret scanning in CI |
| Information disclosure | Health data in logs | Crashlytics excludes health data; audit logs exclude conversations; production error sanitization |
| Denial of service | AI cost abuse / spam | Server-side per-user daily rate limit; client entitlement gate; token/output caps |
| Elevation of privilege | Client deletes others' data / root docs | Rules forbid root-user delete + cross-user writes; deletion via Admin SDK only |
| Prompt injection | Malicious content steering the model | Server-side safety classifier gates before/around the model; system prompt forbids unsafe output and fabrication; grounding restricted to reviewed sources; injection eval cases |
| Unsafe AI output | Emergency/ED/restriction/medication advice | Layered safety: block emergencies/ED/dangerous fasting/severe restriction/child dieting; caution + referral for medication/disease/pregnancy; evaluation gate |
| Supply chain | Compromised dependency | Dependency register + review; `flutter pub outdated`, `npm audit` in CI; pinned versions |
| Secret leakage via VCS | Committed keys | Pre-commit secret checks (hooks), CI secret scan, `.gitignore` for `key.properties`/`.env` |
| Data exfiltration to untrusted MCP/connectors | Prompt-injected tool use | MCP/connector audit + least privilege (`docs/MCP_CONNECTOR_AUDIT.md`); no health data to untrusted connectors |

## Residual risks / recommendations

- Commission an independent security review and penetration test pre-launch.
- Enable Firebase App Check enforcement everywhere and monitor rejects.
- Add anomaly alerting on rate-limit hits and function errors.
- Periodically re-run the AI evaluation suite and review new safety patterns.
