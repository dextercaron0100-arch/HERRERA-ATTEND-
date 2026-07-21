# GeoAttend Payroll — Implementation Plan

## 1. Delivery objective

Build a production-ready attendance and payroll platform consisting of:

- A Flutter employee app for Android and iOS.
- A Next.js administration portal for supervisors, HR, payroll, finance, administrators, and auditors.
- A NestJS modular backend and separate background worker.
- PostgreSQL/PostGIS as the system of record, with Redis, private object storage, and queued jobs.
- Server-authoritative geofence validation and append-only attendance events.
- A versioned, reproducible payroll engine with approval, locking, payslips, and audit history.

The first production release should focus on reliable attendance, payroll calculation, approvals, payslips, and essential reports. Advanced integrations and continuous location tracking are outside the MVP.

## 2. Assumptions and decisions to confirm

Before development begins, the sponsor must confirm:

1. Country/jurisdiction and applicable labor, tax, privacy, and statutory-contribution rules.
2. Pay frequencies, salary divisor, rounding, overtime, holiday, night differential, late, undertime, and absence policies.
3. Organization structure, employee count, branches, worksite coordinates, and expected concurrency.
4. Supported platforms and minimum Android/iOS versions.
5. Whether selfie verification is mandatory, conditional, or excluded from the MVP.
6. Identity provider choice; this plan assumes Amazon Cognito and MFA for privileged roles.
7. Accounting, bank, HRIS, email, SMS, and push-notification integrations required for launch.
8. Data-retention periods for GPS evidence, selfies, documents, payroll records, and audit logs.

No statutory payroll rule should be released without written approval from an authorized payroll or legal specialist.

## 3. MVP scope

### Included

- Employee and administrator authentication, device registration, RBAC, and MFA for privileged users.
- Employee, department, branch, worksite, schedule, holiday, and salary-profile administration.
- Clock-in, clock-out, breaks, server-side geofence checks, GPS accuracy checks, and offline synchronization.
- Append-only attendance events, daily summaries, exception detection, and correction workflows.
- Leave and overtime requests with configurable approvals.
- Versioned payroll policies and line-item calculations.
- Payroll draft, calculation, review, approval, lock, reopen-with-authorization, and payslip generation.
- Employee attendance history, schedule, payroll estimate, and payslip access.
- Daily attendance, timecard, exception, overtime, payroll register, payroll summary, variance, deduction, and audit reports.
- CSV/XLSX/PDF export; one agreed bank or accounting export format if required for launch.
- Audit logs, monitoring, backups, recovery procedures, and privacy controls.

### Deferred

- Continuous background location tracking.
- Facial recognition or liveness matching beyond basic evidence capture.
- Multiple country-specific payroll packages.
- Advanced commissions, expense management, benefits administration, and performance management.
- Predictive analytics, workforce forecasting, and employee scheduling optimization.
- Microservice extraction unless supported by measured scale or team ownership needs.

## 4. Target architecture

```text
Flutter employee app ─┐
                      ├─ HTTPS/REST/OpenAPI ─ NestJS API ─ PostgreSQL + PostGIS
Next.js admin portal ─┘                         │          Redis
                                               │          Private object storage
                                               └─ Queue ─ NestJS worker
                                                          payroll, summaries,
                                                          reports, notifications
```

Key design rules:

- The phone captures evidence; the server makes the attendance decision.
- Attendance events are immutable. Corrections are linked adjustment records.
- Every submission has an idempotency key to make retries and offline sync safe.
- Money uses decimal arithmetic and PostgreSQL `NUMERIC`; time calculations use integer minutes.
- Payroll stores input snapshots, policy versions, calculation explanations, and individual line items.
- Official payroll calculations never run in the mobile app or web UI.
- Begin as a modular monolith plus worker, with clear domain boundaries.

## 5. Delivery roadmap

The expected implementation is 22–26 weeks, followed by a pilot covering two complete payroll cycles. Timing assumes a dedicated cross-functional team and prompt business decisions.

| Phase | Duration | Main outcomes | Exit gate |
|---|---:|---|---|
| 0. Mobilization | 1 week | Ownership, governance, environments, backlog, decision log | Sponsor approves charter and decision owners |
| 1. Discovery and rules | 2 weeks | Signed workflows, payroll rulebook, privacy policy, roles, integrations, acceptance scenarios | HR/payroll/legal sign off requirements |
| 2. UX and architecture | 2 weeks | Mobile/admin prototypes, data model, API contract, threat model, architecture decisions | Design and architecture review passed |
| 3. Platform foundation | 3 weeks | Monorepo, CI/CD, dev/staging infra, auth, RBAC, audit framework, database baseline | Deployable secure vertical slice |
| 4. Workforce and attendance | 4 weeks | Employees, worksites, schedules, mobile clocking, PostGIS validation, offline sync, exceptions | Attendance acceptance and field tests pass |
| 5. Requests and approvals | 2 weeks | Leave, overtime, correction, approval routing, notifications | End-to-end approval scenarios pass |
| 6. Payroll engine | 5 weeks | Rule versions, snapshots, line items, calculations, workflow, locking, payslips | Reference payroll suite and specialist review pass |
| 7. Reporting and exports | 2 weeks | Dashboards, essential reports, exports, reconciliation | Reports reconcile with payroll results |
| 8. Hardening and UAT | 3 weeks | Security, performance, recovery, accessibility, device testing, UAT | No open release-blocking defect |
| 9. Pilot | 2 payroll cycles | Limited branch rollout, parallel payroll, measured support and reconciliation | Both cycles reconcile within agreed tolerance |
| 10. Rollout | 2–4 weeks | Phased company rollout, training, support, operational handover | Production KPIs stable and handover accepted |

## 6. Phase work packages

### Phase 0–2: Define the product before coding

- Appoint product owner, payroll rule owner, security/privacy owner, and technical lead.
- Map current attendance-to-payroll processes and exception paths.
- Produce a signed, effective-dated payroll rulebook with worked examples.
- Define role and data-scope permissions by organization, department, worksite, and salary access.
- Decide geofence radius per worksite based on on-site GPS surveys.
- Prototype the employee clock flow and the administrator exception/payroll flows.
- Create the domain model, API conventions, error model, audit events, and threat model.
- Convert acceptance scenarios into testable backlog items.

### Phase 3: Foundation

- Establish the repository with `apps/mobile` (Android and iOS), `apps/backoffice-web`, `apps/api`, `apps/worker`, shared contracts, database, infrastructure, and tests.
- Provision isolated development and staging environments through infrastructure as code.
- Implement authentication, token validation, device registration, RBAC, MFA, organization scoping, and audit logging.
- Add OpenAPI generation and generated Dart/TypeScript clients.
- Add CI checks for linting, types, unit tests, integration tests, migrations, dependency/security scans, and build artifacts.
- Implement secrets management, encrypted object storage, structured logs, metrics, traces, and health checks.

### Phase 4: Workforce and attendance

- Implement employees, contracts, salary profiles, departments, worksites, assignments, schedules, shifts, holidays, and breaks.
- Build mobile login, device registration, home, schedule, clock, confirmation, history, and sync states.
- Validate device, timestamp, GPS accuracy, PostGIS distance, worksite assignment, schedule, duplication, and mock-location indicators on the server.
- Preserve raw evidence and produce decision reason codes and risk flags.
- Implement encrypted offline queueing, idempotent synchronization, clock-skew detection, and conflict handling.
- Aggregate events into daily attendance summaries and generate missing-punch, excessive-duration, leave-conflict, and location exceptions.
- Test at representative sites and on low-, middle-, and high-range real devices.

### Phase 5: Requests and approvals

- Implement attendance corrections without changing original events.
- Implement leave, overtime, remote-work, and field-assignment requests required for launch.
- Configure supervisor/HR approval routing, deadlines, delegation, comments, evidence, notifications, and full audit history.

### Phase 6: Payroll

- Implement effective-dated employee compensation data and payroll rule versions.
- Create immutable payroll-input snapshots from approved attendance, leave, overtime, allowances, and deductions.
- Calculate and store basic pay, overtime, holiday/rest-day pay, night premium, allowances, bonuses, late/undertime/absence deductions, statutory deductions, tax, other deductions, gross, taxable income, and net pay as explainable line items.
- Implement rounding, currency, timezone, overnight-shift, cross-period, termination, and retroactive-adjustment behavior.
- Add payroll variance checks, controlled manual adjustments, maker-checker approval, locking, authorized reopening, and recalculation history.
- Generate protected payslips with short-lived download links.
- Build a permanent reference suite from payroll-specialist-approved cases and compare outputs against existing payroll for historical periods.

### Phase 7–8: Reports, security, and release readiness

- Build essential attendance, exception, payroll, variance, deduction, and audit reports.
- Add required exports and reconciliation totals.
- Run unit, integration, contract, end-to-end, offline/retry, migration, load, penetration, authorization, and recovery tests.
- Verify payroll isolation, object permissions, signed-link expiry, encryption, rate limits, audit integrity, and separation of duties.
- Complete privacy review, data-retention jobs, backup restore exercise, incident runbooks, administrator training, and user documentation.

### Phase 9–10: Pilot and rollout

- Pilot with one representative branch and a controlled employee group.
- Run the system in parallel with the trusted payroll process for two full cycles.
- Reconcile attendance totals and every payroll line-item class; document and resolve all variances.
- Measure clock success, false geofence rejection, sync delay, exception resolution time, payroll variance, support volume, and user adoption.
- Roll out by branch in waves with a rollback decision at each wave.

## 7. Prioritized product backlog

### Must have for pilot

1. Authentication, MFA, device registration, RBAC, and organization scoping.
2. Employee, worksite, schedule, holiday, compensation, and policy setup.
3. Online/offline clock events with evidence, idempotency, and server-side geofence decisions.
4. Attendance summaries, exceptions, corrections, leave, and overtime approvals.
5. Versioned payroll calculations, snapshots, line items, variance, approvals, and lock.
6. Payslips, audit trail, essential reports, monitoring, backups, and recovery.

### Should have for first company-wide release

- Conditional selfie evidence, richer notification preferences, XLSX/PDF exports, one finance integration, and enhanced dashboard filters.

### Later

- Multiple payroll jurisdictions, advanced biometric/liveness checks, more HR/finance integrations, and analytics.

## 8. Testing and quality gates

Every feature must meet its functional acceptance criteria and include automated tests at the appropriate layer. Release requires:

- All payroll reference cases passing exactly under documented rounding rules.
- Successful duplicate, retry, offline-sync, clock-skew, and correction tests.
- Authorization tests proving cross-organization and unauthorized salary access are denied.
- Representative-site geofence field tests with recorded accuracy and false-rejection results.
- Load tests meeting agreed peak clock-in and payroll batch targets.
- Successful backup restoration and recovery runbook exercise.
- No unresolved critical/high security finding or release-blocking defect.
- Signed UAT approval from HR, payroll, finance, operations, security/privacy, and the product owner.

## 9. MVP acceptance criteria

- An assigned employee can clock in/out at an authorized location online or offline without duplicate records after retries.
- The server records submitted evidence and returns an explainable accepted, rejected, or review decision.
- Unauthorized location, device, schedule, and data-access scenarios are flagged or rejected according to policy.
- Original attendance events cannot be edited; approved corrections remain fully traceable.
- Approved attendance, leave, and overtime flow into the correct payroll period.
- Payroll can be reproduced from its stored input snapshot and rule version.
- Payroll totals match approved reference cases and pilot parallel runs within the formally agreed tolerance.
- Only authorized roles can prepare, approve, reopen, lock, export, or view salary information.
- A locked payroll cannot change without an authorized, audited reopening.
- Employees can view their own attendance and payslips but cannot view another employee's data.

## 10. Team and governance

Recommended core team:

- 1 product owner/business analyst.
- 1 payroll subject-matter expert with authority to approve rules and reference results.
- 1 technical lead/architect.
- 2 backend engineers.
- 1–2 Flutter engineers.
- 1–2 Next.js engineers.
- 1 QA automation engineer plus business UAT participants.
- Part-time UX designer, DevOps/cloud engineer, and security/privacy specialist.

Run two-week iterations, weekly payroll-rule workshops during discovery and payroll development, architecture/security reviews at phase gates, and a fortnightly steering review. Record business and technical decisions with owner, date, rationale, and effective version.

## 11. Principal risks and controls

| Risk | Control |
|---|---|
| Incorrect payroll | Signed rulebook, decimal arithmetic, versioned rules, reference cases, parallel runs, maker-checker approval |
| False geofence rejection | Site survey, configurable radius, GPS accuracy threshold, reason codes, review path, field testing |
| Spoofed attendance | Server calculation, device registration/integrity signals, mock-location flag, optional selfie, risk scoring, audit |
| Offline duplicates or tampering | Encrypted queue, idempotency keys, server timestamps, clock-skew checks, immutable evidence |
| Privacy breach | Data minimization, explicit policy, scoped RBAC, encryption, retention rules, access logs, no default background tracking |
| Unauthorized payroll changes | Separation of duties, approval workflow, lock/reopen controls, immutable audit history |
| Scope expansion | Fixed MVP, change control, phase gates, deferred backlog |
| Integration delay | Agree formats early, use contract fixtures, keep manual controlled export fallback for pilot |

## 12. Success measures

- At least 99.5% successful valid clock submissions during the pilot, excluding confirmed device/network outages.
- Less than 1% false geofence-review rate after site calibration, or another agreed site-specific target.
- No duplicate accepted event from retry or offline synchronization tests.
- 100% payroll reference cases passing.
- Pilot payroll variance within the signed tolerance, with every difference explained.
- 100% of privileged and payroll-changing actions auditable.
- Reduction in attendance correction and payroll preparation time against the documented baseline.

## 13. First 10 working days

1. Name the product owner, payroll authority, technical lead, security/privacy owner, and UAT leads.
2. Collect employee, worksite, schedule, holiday, earnings, deduction, and historical payroll samples using anonymized data where possible.
3. Conduct payroll-rule and attendance-exception workshops.
4. Survey representative worksites for GPS behavior and connectivity.
5. Approve MVP boundaries and choose pilot branch/employees.
6. Produce the payroll rulebook, role-permission matrix, retention policy, and initial acceptance scenarios.
7. Approve architecture decisions, repository conventions, environments, and release gates.
8. Turn the plan into an estimated sprint backlog with named owners.
