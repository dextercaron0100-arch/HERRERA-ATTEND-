import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import { AppShell } from './components/app-shell';
import { SessionProvider } from './components/session-provider';
import { getSession } from './lib/session';
import './styles.css';

const geist = Geist({ subsets: ['latin'], variable: '--font-geist' });
const geistMono = Geist_Mono({ subsets: ['latin'], variable: '--font-geist-mono' });

export const metadata: Metadata = {
  title: { default: 'HERRERA ATTEND', template: '%s | HERRERA ATTEND' },
  description: 'Friendly attendance and payroll operations workspace',
};

export default async function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const session = await getSession();
  return (
    <html lang="en" className={`${geist.variable} ${geistMono.variable}`}>
      <body>
        {session ? <SessionProvider session={session}><AppShell>{children}</AppShell></SessionProvider> : children}
      </body>
    </html>
  );
}
