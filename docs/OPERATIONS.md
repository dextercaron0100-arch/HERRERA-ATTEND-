# Operations runbook

## Health and startup

- Liveness: `GET /api/health/live` checks the API process.
- Readiness: `GET /api/health` verifies PostgreSQL connectivity.
- Start PostgreSQL and Redis before the API and worker. A failed readiness response must keep the instance out of service.

## Backup and recovery

Set `DATABASE_URL`, then run `powershell -File scripts/backup.ps1`. Backups are written outside application artifacts under `backups/` by default. Encrypt and copy them to access-controlled off-site storage.

Restore only into a confirmed target: `powershell -File scripts/restore.ps1 -BackupFile <dump> -ConfirmDatabaseName <database>`. The confirmation must exactly match the database in `DATABASE_URL`. Practice recovery quarterly in a disposable environment and record recovery time and data-loss windows.

## Incident response

1. Remove an unhealthy instance using readiness checks; do not erase logs.
2. Capture request IDs, API/worker logs, affected organization, and time window.
3. Revoke compromised sessions and rotate affected credentials.
4. Restore only after validating the backup and documenting the decision.
5. Reconcile attendance/payroll hashes and audit records before reopening payroll.

## Retention

Run a quarterly data inventory covering attendance GPS evidence, request attachments/evidence, report exports, payslips, payroll records, and audit logs. No automated deletion is enabled because the legal schedule and legal-hold process must be approved first.
