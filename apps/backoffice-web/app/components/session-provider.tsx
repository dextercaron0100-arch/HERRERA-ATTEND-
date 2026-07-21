'use client';

import { createContext, useContext } from 'react';
import type { BackofficeSession } from '../lib/session';

const SessionContext = createContext<BackofficeSession | null>(null);

export function SessionProvider({ session, children }: { session: BackofficeSession; children: React.ReactNode }) {
  return <SessionContext.Provider value={session}>{children}</SessionContext.Provider>;
}

export function useSession() {
  const session = useContext(SessionContext);
  if (!session) throw new Error('useSession must be used within an authenticated SessionProvider');
  return session;
}
