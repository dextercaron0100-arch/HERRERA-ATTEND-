// Clerk requires real API keys to initialize at all. When they aren't configured
// (local development without a Clerk project), the app falls back to the
// employee-ID/password dev login backed by app/lib/session.ts and
// app/api/auth/login and /logout, so the dashboard is still usable without Clerk.
export const isClerkConfigured = Boolean(process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY);
