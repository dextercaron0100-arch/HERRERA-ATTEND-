# Security baseline

Herrera Attend uses Supabase Auth as its identity provider. The API requires `SUPABASE_URL`, verifies access tokens against `${SUPABASE_URL}/auth/v1/.well-known/jwks.json`, and accepts only tokens issued by `${SUPABASE_URL}/auth/v1` for the `authenticated` audience. Use Supabase asymmetric signing keys; never copy a JWT signing secret into the application.

Disable public user registration in Supabase Authentication settings. Create users with dashboard invitations, require email confirmation, and configure the production web origin as the Site URL and an allowed redirect URL. The verified Supabase email must match exactly one active Herrera employee on first login. The API then stores the immutable Supabase user ID in `Employee.authUserId`; later authorization uses that ID rather than an email claim.

Employee organization, role, and active status always come from the Herrera PostgreSQL database. They are never trusted from browser state or editable Supabase user metadata. The API checks organization, actor, and employee identifiers against the resolved employee identity on every request.

Only the Supabase project URL and publishable key may be exposed to browser and mobile clients. Any Supabase secret or service-role key is server-only and is not currently required by the application. Store Railway variables in the appropriate service, never in source control.

Only trusted portal origins belong in `CORS_ORIGINS`. TLS must terminate at a trusted ingress. Payslips and report exports use private, no-store responses. The API applies secure response headers, request IDs, strict DTO validation, and a default limit of 120 requests per minute per client.

Audit logs and immutable attendance corrections are records, not cleanup targets. GPS coordinates and request evidence require an organization-approved retention schedule before automated erasure is introduced. Preserve legal holds and payroll retention obligations.
