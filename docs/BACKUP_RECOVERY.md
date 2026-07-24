# Backup & Recovery Procedure

## What to back up

- **Firestore** (user data, reference content, consent history).
- **Firebase Authentication** users.
- **Cloud Functions** source (in git) + configured secrets/params.
- **Upload keystore** (offline, secure).

## Firestore backups

Enable **scheduled Firestore exports** to a Cloud Storage bucket:

```bash
gcloud firestore export gs://<project>-backups/$(date +%F) \
  --project <project>
```

Automate daily via Cloud Scheduler + a small function or `gcloud` job. Set a
bucket lifecycle/retention policy consistent with `assets/legal/data-retention.md`
(and purge deleted-user data on the backup rotation cycle).

## Restore

```bash
gcloud firestore import gs://<project>-backups/<date> --project <project>
```

Restore to a **staging** project first and validate before touching prod.

## Auth recovery

Firebase Auth cannot be bulk-exported with password hashes via console; use
the Admin SDK (`listUsers`) for an encrypted export if required, stored
securely. Prefer re-onboarding over restoring credentials.

## Disaster-recovery test

Quarterly: restore the latest backup into staging, run smoke tests
(`flutter test`, backend tests), and confirm data integrity.

## Secrets recovery

Secrets live in Google Secret Manager (versioned). Keep an offline record of
which secrets exist (names only) so they can be re-provisioned.
