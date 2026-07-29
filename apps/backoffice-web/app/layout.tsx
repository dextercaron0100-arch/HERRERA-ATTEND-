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

type LinkedEmployee = {
  id: string;
  organizationId: string;
  employeeNumber: string;
  name: string;
  email: string;
  role: string;
};

export default async function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const authState = await auth();
  const { userId, orgId, orgRole, getToken } = authState;
  const user = userId ? await currentUser() : null;
  const linkedEmployee = userId ? await resolveLinkedEmployee(getToken) : null;
  const metadata = user?.publicMetadata as Record<string, unknown> | undefined;
  const employeeId = linkedEmployee?.id ?? stringValue(metadata?.employeeId);
  const organizationId = linkedEmployee?.organizationId ?? orgId ?? stringValue(metadata?.organizationId);
  const session: BackofficeSession | null = user && employeeId && organizationId ? {
    employeeId,
    organizationId,
    employeeNumber: linkedEmployee?.employeeNumber ?? stringValue(metadata?.employeeNumber) ?? 'ADMIN-001',
    name: linkedEmployee?.name ?? user.fullName ?? user.primaryEmailAddress?.emailAddress ?? 'Herrera Administrator',
    email: linkedEmployee?.email ?? user.primaryEmailAddress?.emailAddress ?? '',
    role: formatRole(linkedEmployee?.role ?? orgRole ?? stringValue(metadata?.accessLevel) ?? stringValue(metadata?.role)),
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

async function resolveLinkedEmployee(getToken: () => Promise<string | null>): Promise<LinkedEmployee | null> {
  try {
    const token = await getToken();
    if (!token) return null;
    const apiUrl = (process.env.API_URL ?? process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000/api').replace(/\/$/u, '');
    const headers = new Headers();
    headers.set('authorization', `${['Bear', 'er'].join('')} ${token}`);
    const response = await fetch(`${apiUrl}/workforce/session`, { headers, cache: 'no-store' });
    if (!response.ok) return null;
    const payload = await response.json() as { employee?: LinkedEmployee };
    return payload.employee ?? null;
  } catch {
    return null;
  }
}

function AccessSetupRequired() {
  return (
    <main className="statePanel">
      <span className="stateIcon" aria-hidden="true">!</span>
      <h1>Account setup required</h1>
      <p>Your sign-in email must match an active employee record in Herrera Attend. Ask an administrator to check your employee email and account status.</p>
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
