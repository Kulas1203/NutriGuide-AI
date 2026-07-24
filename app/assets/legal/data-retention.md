# Data Retention Policy

> DRAFT — Review required before publication. Replace {{PLACEHOLDER}} values with the operator's real timelines.

## Principles

We retain personal data only as long as needed to provide the service or as required by law.

## Retention periods

- **Active account data:** retained until you delete it or your account.
- **Account deletion:** account and associated user documents are removed from active systems promptly (target: within {{DELETION_SLA}} of request).
- **Backups:** encrypted backups are rotated and expire within {{BACKUP_RETENTION}}; deleted data is purged from backups on that cycle.
- **Diagnostics:** crash and aggregate usage data (with health details excluded) are retained up to {{DIAGNOSTICS_RETENTION}}.
- **Consent history:** retained for accountability for {{CONSENT_RETENTION}}.

## AI conversations

Stored only when AI history is enabled, and deleted immediately when you disable history or delete your account.
