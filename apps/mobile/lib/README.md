# Application structure

```text
lib/
├── main.dart                         # Application entry point and routing
├── core/
│   ├── database/                     # Drift database and generated schema
│   ├── services/                     # Riverpod providers and session services
│   └── theme/                        # Shared visual tokens
├── data/
│   └── clients/                      # API, attendance and request clients/models
└── features/
    ├── attendance/presentation/      # Home, history and GPS results
    ├── auth/presentation/            # Splash and login
    ├── device/presentation/          # Secure device registration
    ├── leave/presentation/           # Leave dashboard and request form
    ├── payroll/presentation/         # Payroll and payslips
    ├── profile/presentation/         # Profile, notifications and readiness
    └── schedule/presentation/        # Weekly and monthly schedules
```

Use package imports (`package:geoattend_employee/...`) across folders. Keep
feature-specific widgets inside their feature, shared infrastructure under
`core`, and server communication under `data/clients`.

