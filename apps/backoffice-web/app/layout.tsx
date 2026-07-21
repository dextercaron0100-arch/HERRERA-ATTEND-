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
  const session: BackofficeSession | null = user ? {
    employeeId: stringValue(metadata?.employeeId) ?? process.env.NEXT_PUBLIC_HR_ACTOR_ID ?? 'b9336ab3-e69b-40b0-a664-3ff6cb553879',
    organizationId: orgId ?? stringValue(metadata?.organizationId) ?? process.env.NEXT_PUBLIC_ORGANIZATION_ID ?? '5e80ccd3-7b82-495f-a511-db88914085c2',
    employeeNumber: stringValue(metadata?.employeeNumber) ?? 'ADMIN-001',
    name: user.fullName ?? user.primaryEmailAddress?.emailAddress ?? 'Herrera Administrator',
    email: user.primaryEmailAddress?.emailAddress ?? '',
    role: normalizeRole(orgRole ?? stringValue(metadata?.role)),
    expiresAt: Date.now() + 8 * 60 * 60 * 1000,
  } : null;
  return (
    <html lang="en" className={`${geist.variable} ${geistMono.variable}`}>
      <body>
        <ClerkProvider>
          {session ? <SessionProvider session={session}><AppShell>{children}</AppShell></SessionProvider> : children}
        </ClerkProvider>
      </body>
    </html>
  );
}

function stringValue(value: unknown) {
  return typeof value === 'string' && value ? value : undefined;
}

function normalizeRole(role: string | undefined) {
  return role?.replace(/^org:/u, '').toUpperCase() ?? 'ADMIN';
}
