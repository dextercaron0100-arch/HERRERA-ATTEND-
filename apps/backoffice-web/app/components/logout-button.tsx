'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useClerk } from '@clerk/nextjs';
import { LogOut } from 'lucide-react';
import { isClerkConfigured } from '../lib/auth-mode';

export function LogoutButton() {
  return isClerkConfigured ? <ClerkLogoutButton /> : <DevLogoutButton />;
}

function ClerkLogoutButton() {
  const clerk = useClerk();
  const [busy, setBusy] = useState(false);
  async function logout() {
    setBusy(true);
    await clerk.signOut({ redirectUrl: '/login' });
  }
  return <button className="logoutButton" type="button" disabled={busy} onClick={() => void logout()}><LogOut size={16}/>{busy ? 'Signing out…' : 'Sign out'}</button>;
}

function DevLogoutButton() {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  async function logout() {
    setBusy(true);
    await fetch('/api/auth/logout', { method: 'POST' });
    router.replace('/login');
    router.refresh();
  }
  return <button className="logoutButton" type="button" disabled={busy} onClick={() => void logout()}><LogOut size={16}/>{busy ? 'Signing out…' : 'Sign out'}</button>;
}
