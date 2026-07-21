# HERRERA ATTEND — Google Play release checklist

## Build and identity

- Package ID: `com.herrera.attend` (confirm this before the first Play upload; it cannot be changed afterward).
- App name: HERRERA ATTEND.
- Version: update `version` in `pubspec.yaml` for every release.
- Target SDK: Android API 36.
- Build with a live HTTPS endpoint:
  `flutter build appbundle --release --dart-define=API_URL=https://YOUR_API_HOST/api`
- Configure an upload key using `android/key.properties.example`; never commit the key or passwords.
- Enroll the application in Play App Signing.

## App content

- Host `PRIVACY_POLICY.md` at a public, non-editable HTTPS URL.
- Put the same privacy-policy URL in Play Console and inside the app before production.
- Complete the Data Safety form using `PLAY_DATA_SAFETY.md` and verify every answer against the production backend and vendors.
- Declare that the app is an employee attendance/payroll productivity application and is not directed to children.
- Complete content rating, ads declaration (`No ads` unless that changes), app access instructions, and test credentials.
- Supply support email, website, store description, screenshots, feature graphic, and final launcher icon.

## Testing and rollout

- Upload first to Internal testing and run the Play pre-launch report.
- Test login, logout, biometric fallback, device registration, denied/approximate location, GPS inside/outside the worksite, offline retry, duplicate clock prevention, requests, payroll and PDF payslip.
- Test at least one Android 16/API 36 device and representative low/mid/high-range physical devices.
- Resolve all Android vitals, crashes, ANRs, accessibility findings, and policy warnings.
- If the developer account is a new personal account, complete the required closed test before requesting production access.
- Roll out gradually and monitor crashes, ANRs, failed clock events, GPS rejection rates, and API errors.

## Production controls

- Replace development password login with the configured production identity provider/JWT issuer.
- Keep all API and document traffic on HTTPS.
- Rotate test secrets and remove demo accounts/data from production.
- Verify tenant isolation and employee-only access to payroll, attendance and payslips.
- Configure retention/deletion handling, backups, restore procedures, incident contacts and audit monitoring.

