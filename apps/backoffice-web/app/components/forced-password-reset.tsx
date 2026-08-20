'use client';

import { FormEvent, useState } from 'react';
import { KeyRound } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { apiRequest } from '../lib/api';
import { useSession } from './session-provider';

export function ForcedPasswordReset() {
  const router = useRouter();
  const session = useSession();
  const [password, setPassword] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (password.length < 8) {
      setError('Use at least 8 characters.');
      return;
    }
    if (password !== confirmation) {
      setError('Passwords do not match.');
      return;
    }

    setSaving(true);
    setError(null);
    try {
      await apiRequest('/workforce/password-reset/complete', { method: 'POST', body: JSON.stringify({ password }) });
      router.refresh();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Unable to finish the password change.');
    } finally {
      setSaving(false);
    }
  }

  return <main className="statePanel"><span className="stateIcon" aria-hidden="true"><KeyRound size={22}/></span><h1>Create your private password</h1><p>Signed in as {session.email}. Your temporary password worked, but you must replace it before continuing.</p><form className="herreraAuthCard authResetForm" onSubmit={event => void submit(event)}><label className="herreraAuthLabel" htmlFor="forced-new-password">New password</label><input id="forced-new-password" className="herreraAuthInput" type="password" minLength={8} autoComplete="new-password" value={password} onChange={event => setPassword(event.target.value)} required/><label className="herreraAuthLabel" htmlFor="forced-confirm-password">Confirm password</label><input id="forced-confirm-password" className="herreraAuthInput" type="password" minLength={8} autoComplete="new-password" value={confirmation} onChange={event => setConfirmation(event.target.value)} required/>{error && <p className="authMessage authError" role="alert">{error}</p>}<button className="herreraAuthButton" type="submit" disabled={saving}>{saving ? 'Saving…' : 'Set new password'}</button></form></main>;
}
