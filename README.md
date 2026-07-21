# GeoAttend Payroll

An initial production-oriented vertical slice for the attendance and payroll plan in `IMPLEMENTATION_PLAN.md`.

## Repository structure

```text
apps/
  mobile/             Flutter employee application
    android/          Android platform configuration
    ios/              iOS platform configuration
    lib/              Shared Flutter/Dart application code
  backoffice-web/     Next.js HR and payroll back-office
  api/                NestJS API
  worker/             Background jobs
packages/
  contracts/          Shared TypeScript contracts
prisma/               Database schema, migrations, and seed data
docs/                 Security, operations, and UAT documentation
```

Android and iOS intentionally live inside the same Flutter project so both
platforms share one tested application codebase while retaining separate native
configuration folders.

## What is implemented

- NestJS API with JWT/JWKS validation, tenant/actor consistency checks, rate limiting, security headers, strict validation, readiness checks, idempotent attendance capture, worksite assignment checks, GPS-accuracy handling, and server-authoritative geofence decisions.
- PostgreSQL schema for organizations, employees, worksites, immutable attendance events/corrections, versioned payroll policies, payroll snapshots/line items, locking state, and audit records.
- Redis/BullMQ worker foundation for attendance summaries and payroll batches.
- Responsive Next.js HR operations dashboard.
- Flutter employee clocking shell (source only; Flutter SDK is required to build).
- Workforce structures for departments, weekly schedules, shifts, holidays, daily summaries, linked corrections, and typed attendance exceptions.
- Flutter Android/iOS/web targets with live GPS evidence, idempotent submissions, and a persistent offline retry queue.
- Admin attendance and exception review routes.
- Phase 5 request workflows for leave, overtime, remote work, field assignment, and attendance corrections, including multi-step approval policies, delegation, comments, notifications, audit events, and approval-created correction records.
- Phase 6 payroll engine with effective-dated compensation, approved policy versions, immutable input snapshots, decimal line items and explanations, manual adjustments, calculation hashes, maker-checker approval, lock/reopen history, and employee-scoped PDF payslips.
- Phase 7 reconciled daily-attendance, timecard, exception, overtime, payroll register/summary/variance/deduction, and audit reports with authorized CSV/PDF exports, content hashes, and export audit history.
- Phase 9 pilot controls for cohort enrollment, two-cycle parallel payroll, line-level trusted-system reconciliation, tolerance gates, independent finance sign-off, completion status, and auditable pilot actions.
- Docker Compose development services and geofence unit tests.

This is a foundation, not a legally approved payroll release. Statutory rules are deliberately not hard-coded; only an explicitly labeled demo policy is seeded.

The seeded payroll policy is explicitly `DEMO_ONLY_NOT_STATUTORY`. Replace it with a payroll-specialist-approved policy and reference cases before any real payroll run.

For the mobile app, pass seeded identifiers and the API endpoint at runtime: `flutter run --dart-define=API_URL=http://10.0.2.2:4000/api --dart-define=EMPLOYEE_ID=<id> --dart-define=WORKSITE_ID=<id>`.

## Run locally

1. Copy `.env.example` to `.env`.
2. Start dependencies: `docker compose up -d`.
3. Install packages: `npm install`.
4. Generate and migrate: `npm run db:generate` then `npm run db:migrate -- --name initial`.
5. Seed demo records: `npm run db:seed`.
6. Start API: `npm run dev:api` (Swagger at `http://localhost:4000/docs`).
7. Start admin: `npm run dev:web` (dashboard at `http://localhost:3000`).
8. Start worker: `npm run dev -w @geoattend/worker`.

Run the mobile app from `apps/mobile`. Android uses the `android/` platform
folder and iOS uses `ios/`:

```bash
cd apps/mobile
flutter pub get
flutter run
```

Run verification with `npm test` and `npm run build`.

## Release controls

Before any shared deployment, switch `AUTH_MODE` to `production`, configure the identity-provider values in `.env.example`, follow `docs/SECURITY.md`, and complete `docs/UAT.md`. Backup and recovery procedures are in `docs/OPERATIONS.md`.

Before pilot use, add device attestation, a specialist-approved payroll rulebook/reference suite, protected object storage for payslips, centralized audit middleware, and generated API clients.

## Attendance decision behavior

- Accurate and inside radius: `ACCEPTED`.
- Accurate and outside radius: `REJECTED`.
- GPS accuracy worse than the site's threshold: `REVIEW` (avoids a false definitive rejection).
- Repeated idempotency key: returns the original event result without creating a duplicate.
