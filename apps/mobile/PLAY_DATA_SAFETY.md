# Data Safety working declaration

This is an engineering inventory, not a substitute for the final declaration by the data controller. Re-check production behavior and every third-party service before submission.

| Data type | Collected | Purpose | Notes |
|---|---:|---|---|
| Precise and approximate location | Yes | App functionality, fraud prevention/security | Captured when recording attendance and sent to the employer's API. Not used for advertising. |
| Name, email and employee number | Yes | Account management, app functionality | Employer-managed profile data. |
| Attendance and work schedule | Yes | App functionality | Clock events, timestamps, decisions, schedules and summaries. |
| Payroll and leave information | Yes | App functionality | Payslip lines, balances and employee requests. |
| Device identifier/name | Yes | Security, fraud prevention | Used for employer-approved device registration. |
| App diagnostics | Confirm before release | Analytics/stability | Declare if production logging, crash reporting or monitoring can associate diagnostics with a user/device. |
| Photos/files | No in current mobile implementation | — | Re-evaluate if evidence upload is added. |

Current engineering controls:

- Data is encrypted in transit when the required production HTTPS API is configured.
- Authentication/session values are stored using platform secure storage.
- Android cloud backup is disabled for application data.
- Location is requested during attendance actions; background location permission is not declared.
- The application contains no advertising SDK.

Questions the organization must finalize:

- Legal entity/data-controller name and privacy contact.
- Retention periods for attendance, GPS, device, request and payroll information.
- Whether vendors/processors receive any collected data.
- Employee access, correction, export and deletion procedures under applicable employment and privacy law.
- Whether employer-provisioned accounts qualify for an account-deletion exception and how deletion requests are handled.

