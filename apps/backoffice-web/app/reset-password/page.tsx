'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '../lib/supabase/client';

export default function ResetPasswordPage() {
  const router = useRouter();
  const [password, setPassword] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  async function submit(event: React.FormEvent) {
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
    const { error: updateError } = await createClient().auth.updateUser({ password });
    setSaving(false);
    if (updateError) {
      setError(updateError.message);
      return;
    }
    router.replace('/');
    router.refresh();
  }

  return (
    <main className="statePanel">
      <h1>Choose a new password</h1>
      <form className="herreraAuthCard authResetForm" onSubmit={event => void submit(event)}>
        <label className="herreraAuthLabel" htmlFor="new-password">New password</label>
        <input id="new-password" className="herreraAuthInput" type="password" minLength={8} autoComplete="new-password" value={password} onChange={event => setPassword(event.target.value)} required />
        <label className="herreraAuthLabel" htmlFor="confirm-password">Confirm password</label>
        <input id="confirm-password" className="herreraAuthInput" type="password" minLength={8} autoComplete="new-password" value={confirmation} onChange={event => setConfirmation(event.target.value)} required />
        {error && <p className="authMessage authError" role="alert">{error}</p>}
        <button className="herreraAuthButton" type="submit" disabled={saving}>{saving ? 'Saving…' : 'Update password'}</button>
      </form>
    </main>
  );
}
