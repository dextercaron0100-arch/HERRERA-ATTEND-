import type { Metadata } from 'next';
import { ClerkProvider } from '@clerk/nextjs';
import { auth, currentUser } from '@clerk/nextjs/server';
import { Geist, Geist_Mono } from 'next/font/google';
import { AppShell } from './components/app-shell';
import { SessionProvider } from './components/session-provider';
import type { BackofficeSession } from './lib/session';
import './styles.css';

const geist = Geist({ subsets: ['latin'], variable: '--font-geist' });
const geistMono = Geist_Mono({ subsets: ['latin'], variable: '--font-geist-mono' });

export const metadata: Metadata = {
  title: { default: 'HERRERA ATTEND', template: '%s | HERRERA ATTEND' },
  description: 'Friendly attendance and payroll operations workspace',
};

export default async function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const { userId, orgId, orgRole } = await auth();
  const user = userId ? await currentUser() : null;
  const metadata = user?.publicMetadata as Record<string, unknown> | undefined;
  const employeeId = stringValue(metadata?.employeeId);
  const organizationId = orgId ?? stringValue(metadata?.organizationId);
  const session: BackofficeSession | null = user && employeeId && organizationId ? {
    employeeId,
    organizationId,
    employeeNumber: stringValue(metadata?.employeeNumber) ?? 'ADMIN-001',
    name: user.fullName ?? user.primaryEmailAddress?.emailAddress ?? 'Herrera Administrator',
    email: user.primaryEmailAddress?.emailAddress ?? '',
    role: formatRole(orgRole ?? stringValue(metadata?.accessLevel) ?? stringValue(metadata?.role)),
    expiresAt: Date.now() + 8 * 60 * 60 * 1000,
  } : null;
  return (
    <html lang="en" className={`${geist.variable} ${geistMono.variable}`}>
      <body>
        <ClerkProvider>
          {session
            ? <SessionProvider session={session}><AppShell>{children}</AppShell></SessionProvider>
            : user
              ? <AccessSetupRequired />
              : children}
        </ClerkProvider>
      </body>
    </html>
  );
}

function AccessSetupRequired() {
  return (
    <main className="statePanel">
      <span className="stateIcon" aria-hidden="true">!</span>
      <h1>Account setup required</h1>
      <p>Your sign-in is valid, but this Clerk account has not been linked to a Herrera employee and organization.</p>
    </main>
  );
}

function stringValue(value: unknown) {
  return typeof value === 'string' && value ? value : undefined;
}

function formatRole(role: string | undefined) {
  const normalized = role?.replace(/^org:/u, '').replaceAll('_', ' ').toLowerCase() ?? 'admin';
  return normalized.replace(/\b\w/gu, character => character.toUpperCase());
}
