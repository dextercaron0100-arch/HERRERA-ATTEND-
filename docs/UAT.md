# User acceptance checklist

- Employee can clock in/out inside a worksite and sees the server decision.
- Poor GPS accuracy routes an event to review; an outside event is rejected.
- Offline submissions retry once without duplicate events.
- Supervisor can approve, reject, comment, and delegate a request.
- Cross-organization and mismatched actor requests are denied in production auth mode.
- Payroll cannot calculate without an approved policy, and maker-checker rules prevent self-approval.
- Locked payroll requires a reason to reopen and retains history.
- Employee can access only their own payslip; export responses are private/no-store.
- CSV/PDF reports reconcile to daily summaries and payroll lines.
- Liveness stays available while readiness reports a database outage.
- Backup restores successfully into a disposable database and hashes reconcile.
