'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { LogOut } from 'lucide-react';
import { createClient } from '../lib/supabase/client';

export function LogoutButton() {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  async function logout() {
    setBusy(true);
    await createClient().auth.signOut();
    router.replace('/login');
    router.refresh();
  }
  return <button className="logoutButton" type="button" disabled={busy} onClick={() => void logout()}><LogOut size={16}/>{busy ? 'Signing out…' : 'Sign out'}</button>;
}
