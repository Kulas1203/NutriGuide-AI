# MCP & Connector Audit

Per the master prompt, integrations were reviewed for reputation, requested
permissions, and data access, following least privilege. **No user health
information, credentials, source code, or secrets were sent to any third-party
connector.** Integrations were used only where they materially improved the
work, and disabled when their task was complete.

## Used

| Integration | Purpose in this build | Data shared | Least-privilege notes |
|---|---|---|---|
| GitHub (repo + PR) | Version control, branch pushes | Source code only (this repo) | Scoped to the single working repo; no secrets committed |
| Local toolchain (Flutter, Node, Android SDK) | Build, analyze, test | None external | Ran locally; datasets generated locally |

## Considered but NOT used (and why)

| Integration | Why not used |
|---|---|
| Design tools (Figma/Canva/Gamma/Picsart) | The design system was built directly in Flutter as reusable tokens/components; no external design asset upload was needed, avoiding sending product/UI data outward |
| Hosting/deploy connectors (Vercel/Supabase/Lovable) | Backend targets Firebase/Cloud Functions per requirements; using unrelated hosts would add data-sharing surface for no benefit |
| Email/Docs/Drive/Notion connectors | No need to exfiltrate project or user data to external productivity tools |
| Media-generation connectors | Store graphics/screenshots are specified as owner deliverables; no health or user data involved |

## Prompt-injection protection

External content (e.g. GitHub issue/PR/webhook text, MCP tool output) is
treated as untrusted. The AI Coach pipeline additionally defends against
injection with a server-side safety classifier and a system prompt that
forbids unsafe output and fabrication, plus grounding restricted to reviewed
sources. See `docs/THREAT_MODEL.md`.

## Autonomy limits

No autonomous publishing, production deletion, billing changes, or destructive
database operations were performed. Production/AAB signing and Play submission
require explicit human action (see `docs/RELEASE_CHECKLIST.md`).
