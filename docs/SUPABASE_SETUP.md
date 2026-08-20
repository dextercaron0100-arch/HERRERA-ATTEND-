# Supabase and Railway setup

## 1. Create and secure the Supabase project

1. Create a Supabase project and copy its Project URL and publishable key from the Connect dialog.
2. In Authentication settings, disable public user signups and require email confirmation.
3. In JWT signing keys, use an asymmetric signing key so Railway can validate tokens through the public JWKS endpoint.
4. Set the Site URL to the production back-office origin.
5. Add these redirect URLs:
   - `https://YOUR-BACKOFFICE-DOMAIN/auth/confirm`
   - `https://YOUR-BACKOFFICE-DOMAIN/reset-password`
   - `com.herrera.attend://reset-password`
   - Local equivalents on `http://localhost:3000` for development.

For dashboard invitations, configure the invitation email link as:

```text
{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=invite&next=/reset-password
```

The application also supports Supabase's PKCE `code` callback used by browser password recovery.

## 2. Configure Railway

Set these variables on the API service:

```text
SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
CORS_ORIGINS=https://YOUR-BACKOFFICE-DOMAIN
DATABASE_URL=${{Postgres.DATABASE_URL}}
```

Set these variables on the back-office service:

```text
NEXT_PUBLIC_SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
API_URL=https://YOUR-API-DOMAIN/api
NEXT_PUBLIC_API_URL=https://YOUR-API-DOMAIN/api
```

Apply the Prisma migration before starting the updated API:

```bash
npx prisma migrate deploy
```

The repository's `railway.json` already runs this as its pre-deploy command.

## 3. Invite and link users

1. Ensure each employee has the correct unique work email in Herrera Attend.
2. In Supabase Authentication > Users, send an invitation to that exact email.
3. The user opens the invitation and chooses a password.
4. On first API request, Herrera Attend matches the verified email once and stores the Supabase user ID in `Employee.authUserId`.
5. Later requests use the immutable user ID. Changing email claims does not relink the account.

Back-office access is limited to `SUPERVISOR`, `HR`, `PAYROLL`, `FINANCE`, `ADMIN`, and `AUDITOR`. Employees can use the Flutter app with the same Supabase account.

## 4. Build Flutter

```bash
flutter build apk \
  --dart-define=API_URL=https://YOUR-API-DOMAIN/api \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Use the equivalent `flutter build ios` command for iOS. Supabase sessions are stored with `flutter_secure_storage`. Android and iOS are configured to reopen the app at `com.herrera.attend://reset-password` for password recovery.
