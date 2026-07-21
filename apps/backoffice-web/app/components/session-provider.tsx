'use client';

import { useAuth } from '@clerk/nextjs';
import { createContext, useContext, useEffect } from 'react';
import type { BackofficeSession } from '../lib/session';
import { setApiTokenProvider } from '../lib/api';

const SessionContext = createContext<BackofficeSession | null>(null);

export function SessionProvider({ session, children }: { session: BackofficeSession; children: React.ReactNode }) {
  const { getToken } = useAuth();
  useEffect(() => {
    setApiTokenProvider(() => getToken());
    return () => setApiTokenProvider(null);
  }, [getToken]);
  return <SessionContext.Provider value={session}>{children}</SessionContext.Provider>;
}

export function useSession() {
  const session = useContext(SessionContext);
  if (!session) throw new Error('useSession must be used within an authenticated SessionProvider');
  return session;
}
