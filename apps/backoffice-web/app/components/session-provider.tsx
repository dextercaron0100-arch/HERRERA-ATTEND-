'use client';

import { createContext, useContext, useEffect, useMemo } from 'react';
import type { BackofficeSession } from '../lib/session';
import { setApiTokenProvider } from '../lib/api';
import { createClient } from '../lib/supabase/client';

const SessionContext = createContext<BackofficeSession | null>(null);

export function SessionProvider({ session, children }: { session: BackofficeSession; children: React.ReactNode }) {
  const supabase = useMemo(() => createClient(), []);

  useEffect(() => {
    setApiTokenProvider(async () => {
      const { data } = await supabase.auth.getSession();
      return data.session?.access_token ?? null;
    });
    return () => setApiTokenProvider(null);
  }, [supabase]);

  return <SessionContext.Provider value={session}>{children}</SessionContext.Provider>;
}

export function useSession() {
  const session = useContext(SessionContext);
  if (!session) throw new Error('useSession must be used within an authenticated SessionProvider');
  return session;
}
