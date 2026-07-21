'use client';

import { useState } from 'react';
import { useClerk } from '@clerk/nextjs';
import { LogOut } from 'lucide-react';

export function LogoutButton() {
  const clerk = useClerk();
  const [busy, setBusy] = useState(false);
  async function logout() {
    setBusy(true);
    await clerk.signOut({ redirectUrl: '/login' });
  }
  return <button className="logoutButton" type="button" disabled={busy} onClick={() => void logout()}><LogOut size={16}/>{busy ? 'Signing out…' : 'Sign out'}</button>;
}
