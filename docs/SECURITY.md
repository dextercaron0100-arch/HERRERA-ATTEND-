# Security baseline

GeoAttend defaults to `AUTH_MODE=development` for local use. Any shared or production environment must set `AUTH_MODE=production` and configure `JWT_JWKS_URL`, `JWT_ISSUER`, and `JWT_AUDIENCE`.

Production tokens must contain `sub` and `organization_id`. Employee tokens should also contain `employee_id` and `role=EMPLOYEE`. The API rejects organization, actor, and employee identifiers that conflict with those claims. Authorization remains enforced in the API; a web proxy must never be the only authorization layer.

Only trusted portal origins belong in `CORS_ORIGINS`. TLS must terminate at a trusted ingress. Payslips and report exports use private, no-store responses. Secrets must live in a secret manager, never source control.

The API applies secure response headers, request IDs, strict DTO validation, and a default limit of 120 requests per minute per client. Adjust the rate only after load testing.

Audit logs and immutable attendance corrections are records, not cleanup targets. GPS coordinates and request evidence require an organization-approved retention schedule before automated erasure is introduced. Preserve legal holds and payroll retention obligations.
