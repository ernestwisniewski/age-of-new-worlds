# Data retention

This page records automatic deletion currently implemented by the repository. It is an operational inventory, not a privacy policy. Backups are separate copies with their own lifecycle.

## Automatic retention

| Data | Rule |
| --- | --- |
| Serverpod session logs | 90 days or 100,000 rows, whichever limit is reached first. |
| JWT refresh tokens | Configured token lifetime plus 7 days. |
| Steam authentication requests | 7 days after `expiresAt`. |
| Authentication rate-limit attempts | 7 days after `attemptedAt`. |

Authentication maintenance runs every six hours in bounded batches. Backlogs schedule a short follow-up rather than allowing one job to monopolize the server.

## Data without automatic age-based deletion

The repository currently has no automatic physical retention deadline for:

- accounts and profiles;
- game matches and participant rows;
- recipient snapshots;
- game event and command ledgers.

There is also no user-facing account-deletion flow. Signing out revokes the session and clears local credentials; it does not delete the account.

A destructive retention policy for these records requires a product and privacy decision, transactional cleanup rules, recovery/support requirements, and an explicit backup policy.

## Backups

`deploy/postgres/backup.sh` keeps local dump files for 14 days by default. `AONW_BACKUP_RETENTION_DAYS` overrides the value. The script does not create an offsite copy.

Production and staging backups must be stored on durable storage or copied elsewhere. See [PostgreSQL backup and restore](postgres-backup.md).

## Sources

- `server/config/*.yaml`
- `server/lib/src/auth/auth_maintenance_service.dart`
- `server/lib/src/auth/auth_maintenance_future_call.dart`
- `server/lib/src/game/service/`
- `deploy/postgres/backup.sh`

Update this document whenever a cutoff, maintenance cadence, batch limit, or covered data category changes.
