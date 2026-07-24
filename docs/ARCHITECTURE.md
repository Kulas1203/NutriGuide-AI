# NutriGuide AI — Architecture

NutriGuide AI is a Flutter (Android) wellness and nutrition app with a secure
Firebase/Cloud Functions backend and an evidence-grounded AI Nutrition Coach.
It is local-first (fully usable offline) and privacy-first (health data is
treated as sensitive and never used for advertising).

## Guiding principles

- **Clean, feature-first architecture.** Each feature owns `domain/` (pure
  models + logic), `data/` (repositories), `application/` (Riverpod
  controllers) and `presentation/` (widgets).
- **Local-first.** All user data persists through `LocalStore`; the sync layer
  mirrors it to Firestore. The app works offline and never blocks on network.
- **Secrets stay server-side.** The app holds only public client identifiers.
  AI provider keys, service accounts and prompts live in the backend secret
  manager. A production build cannot use development stubs (enforced by
  `AppEnvironment.guardProductionIntegrity`).
- **Safety is layered.** A client pre-screen and an authoritative server-side
  classifier both gate the AI Coach; high-risk inputs never receive a diet
  answer.

## Layers

| Layer | Location | Responsibility |
|-------|----------|----------------|
| Design system | `app/lib/core/design` | Tokens, theme, reusable components |
| Storage | `app/lib/core/storage` | `LocalStore` local-first JSON store |
| Domain | `app/lib/features/*/domain` | Pure models + business logic (tested) |
| Data | `app/lib/features/*/data` | Repositories, auth, AI service adapters |
| Application | `app/lib/features/*/application` | Riverpod `Notifier` controllers |
| Presentation | `app/lib/features/*/presentation` | Screens and widgets |
| Backend | `backend/functions/src` | AI orchestration, safety, validation, lifecycle |

## System architecture

```mermaid
flowchart TB
  subgraph Device["Android device (Flutter app)"]
    UI["Presentation (GoRouter + Riverpod)"]
    CTRL["Controllers (Notifier)"]
    REPO["Repositories"]
    LS["LocalStore (offline-first)"]
    SAFE1["Client safety pre-screen"]
    UI --> CTRL --> REPO --> LS
    CTRL --> SAFE1
  end
  subgraph Backend["Firebase / Cloud Functions"]
    FN["coachAsk / validateMealPlan / exportMyData / deleteMyAccount"]
    SAFE2["Authoritative safety classifier"]
    ORCH["AI Orchestrator (+ grounding, retry, fallback)"]
    RL["Rate limiter"]
    AUD["Audit log (no health data)"]
    FN --> SAFE2 --> ORCH
    FN --> RL
    FN --> AUD
  end
  subgraph Google["Google Cloud"]
    AUTH["Firebase Auth"]
    FS["Cloud Firestore (per-user rules)"]
    APPCHK["App Check / Play Integrity"]
    SM["Secret Manager"]
  end
  AI["AI provider (DeepSeek)"]

  REPO -->|"ID token + App Check"| FN
  REPO -->|auth| AUTH
  REPO -->|sync| FS
  FN --> APPCHK
  ORCH -->|server-only key| SM
  ORCH --> AI
```

## Authentication flow

```mermaid
sequenceDiagram
  participant App
  participant Auth as Firebase Auth (REST)
  participant Store as flutter_secure_storage
  App->>Auth: signInWithPassword(email, password)
  Auth-->>App: idToken + refreshToken
  App->>Store: persist refreshToken (encrypted)
  Note over App: idToken cached in memory, refreshed on demand
  App->>Auth: token refresh when expiring
  Auth-->>App: new idToken
```

## AI request flow

```mermaid
sequenceDiagram
  participant App
  participant CS as Client safety pre-screen
  participant BE as coachAsk (Cloud Function)
  participant SS as Server safety classifier
  participant GR as Grounding retrieval
  participant M as AI provider
  App->>CS: classify(question)
  alt blocking (emergency / ED / restriction)
    CS-->>App: safe message, NO model call
  else allow / caution
    App->>BE: question + context (+ ID token, App Check)
    BE->>BE: verify App Check + auth + rate limit
    BE->>SS: classify(question)
    alt blocking
      SS-->>BE: safe message
      BE-->>App: safe answer (no model)
    else allow
      BE->>GR: retrieve reviewed sources
      GR-->>BE: grounding chunks (may be empty)
      BE->>M: system + grounding + question (structured tool)
      M-->>BE: streamed deltas + CoachAnswer
      BE-->>App: NDJSON stream (delta..., final)
    end
  end
```

## Meal-plan generation

```mermaid
flowchart LR
  P["Profile + targets"] --> G["PlanGenerator (deterministic, seeded)"]
  R["Recipe dataset (bundled)"] --> G
  G --> V["PlanValidator (client)"]
  V -->|blocking issues| X["Reject + advise relaxing filters"]
  V -->|acceptable| S["Save active plan"]
  S -->|sync| SV["validateMealPlan (server) re-check"]
```

## Data-deletion flow

```mermaid
sequenceDiagram
  participant App
  participant Auth
  participant FN as deleteMyAccount
  App->>App: confirm + collect password
  App->>Auth: reauthenticate (recent sign-in)
  App->>FN: call (ID token + App Check)
  FN->>FN: require auth_time < 5 min
  FN->>FN: delete Firestore subtree + rate limits
  FN->>Auth: deleteUser(uid)
  FN->>FN: audit log (uid + action only)
  App->>App: wipe LocalStore, sign out
```

## Offline synchronization

```mermaid
flowchart LR
  A["User action"] --> LS["LocalStore (immediate)"]
  LS --> Q["Pending-sync flag on records"]
  Q -->|online| SY["Sync service"]
  SY -->|dedupe by id| FS["Firestore"]
  SY --> LS
  Note1["Duplicate logs prevented by stable ids"]
```

## Safety-escalation flow

```mermaid
flowchart TB
  I["User message"] --> C{"Category?"}
  C -->|emergency / self-harm| E["Immediate-care message, NO diet answer"]
  C -->|eating disorder / dangerous fasting / severe restriction / child| B["Supportive referral, NO plan"]
  C -->|medication / disease / pregnancy| W["Answer generally + professional referral"]
  C -->|none| A["Normal grounded answer + sources + confidence"]
```

## Monetization (feature-flagged)

Monetization ships behind `FeatureFlags.monetizationEnabled` (default off). The
entitlement logic (`features/settings/domain/entitlements.dart`) already
gates AI fair-use limits, advanced analytics and multiple programs, while
account deletion and data export are **never** gated. Google Play Billing is
the integration slot; the app launches fully functional without it.

## State management

Riverpod `Notifier`/`NotifierProvider` (Riverpod 3.x). Controllers read
repositories via `ref.watch` in `build()`; providers are defined in
`app/lib/app/providers.dart`. GoRouter redirects on session + profile state.
