import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import { AppShell } from './components/app-shell';
import { SessionProvider } from './components/session-provider';
import { LogoutButton } from './components/logout-button';
import { createClient } from './lib/supabase/server';
import type { BackofficeSession } from './lib/session';
import 'leaflet/dist/leaflet.css';
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

const BACKOFFICE_ROLES = new Set(['SUPERVISOR', 'HR', 'PAYROLL', 'FINANCE', 'ADMIN', 'AUDITOR']);

export default async function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const auth = await loadAuthState();
  const session: BackofficeSession | null = auth.employee && auth.expiresAt ? {
    employeeId: auth.employee.id,
    organizationId: auth.employee.organizationId,
    employeeNumber: auth.employee.employeeNumber,
    name: auth.employee.name,
    email: auth.employee.email,
    role: formatRole(auth.employee.role),
    expiresAt: auth.expiresAt,
  } : null;

  return (
    <html lang="en" className={`${geist.variable} ${geistMono.variable}`}>
      <body>
        {session
          ? <SessionProvider session={session}><AppShell>{children}</AppShell></SessionProvider>
          : auth.signedIn
            ? <AccessSetupRequired />
            : children}
      </body>
    </html>
  );
}

async function loadAuthState(): Promise<{
  signedIn: boolean;
  employee: LinkedEmployee | null;
  expiresAt: number | null;
}> {
  try {
    const supabase = await createClient();
    const { data: claimsData } = await supabase.auth.getClaims();
    if (!claimsData?.claims?.sub) return { signedIn: false, employee: null, expiresAt: null };

    const { data: sessionData } = await supabase.auth.getSession();
    const accessToken = sessionData.session?.access_token;
    if (!accessToken) return { signedIn: false, employee: null, expiresAt: null };

    const employee = await resolveLinkedEmployee(accessToken);
    return {
      signedIn: true,
      employee,
      expiresAt: sessionData.session?.expires_at ? sessionData.session.expires_at * 1000 : Date.now() + 60 * 60 * 1000,
    };
  } catch {
    return { signedIn: false, employee: null, expiresAt: null };
  }
}

async function resolveLinkedEmployee(accessToken: string): Promise<LinkedEmployee | null> {
  try {
    const apiUrl = (process.env.API_URL ?? process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000/api').replace(/\/$/u, '');
    const response = await fetch(`${apiUrl}/workforce/session`, {
      headers: { authorization: `Bearer ${accessToken}` },
      cache: 'no-store',
    });
    if (!response.ok) return null;
    const payload = await response.json() as { employee?: LinkedEmployee };
    const employee = payload.employee ?? null;
    return employee && BACKOFFICE_ROLES.has(employee.role) ? employee : null;
  } catch {
    return null;
  }
}

function AccessSetupRequired() {
  return (
    <main className="statePanel">
      <span className="stateIcon" aria-hidden="true">!</span>
      <h1>Account setup required</h1>
      <p>Your verified Supabase email must match an active employee with back-office access. Ask an administrator to check your employee email, role, and account status.</p>
      <LogoutButton />
    </main>
  );
}

function formatRole(role: string) {
  return role.replaceAll('_', ' ').toLowerCase().replace(/\b\w/gu, character => character.toUpperCase());
}
