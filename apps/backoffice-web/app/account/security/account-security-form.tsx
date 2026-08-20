'use client';

import { FormEvent, useMemo, useState } from 'react';
import { KeyRound, MailCheck, ShieldCheck } from 'lucide-react';
import { createClient } from '../../lib/supabase/client';

export function AccountSecurityForm({ email, role }: { email: string; role: string }) {
  const supabase = useMemo(() => createClient(), []);
  const [currentPassword, setCurrentPassword] = useState('');
  const [password, setPassword] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [saving, setSaving] = useState(false);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  async function updatePassword(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (password.length < 8) {
      setError('Use at least 8 characters for the new password.');
      return;
    }
    if (password !== confirmation) {
      setError('New passwords do not match.');
      return;
    }
    if (currentPassword === password) {
      setError('Choose a new password that differs from the current password.');
      return;
    }

    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      const { error: verificationError } = await supabase.auth.signInWithPassword({ email, password: currentPassword });
      if (verificationError) {
        setError('The current password is incorrect.');
        return;
      }
      const { error: updateError } = await supabase.auth.updateUser({ password });
      if (updateError) {
        setError(updateError.message);
        return;
      }
      setCurrentPassword('');
      setPassword('');
      setConfirmation('');
      setNotice('Password updated successfully.');
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Unable to update the password.');
    } finally {
      setSaving(false);
    }
  }

  async function sendRecoveryEmail() {
    setSending(true);
    setError(null);
    setNotice(null);
    try {
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/auth/confirm?next=/reset-password`,
      });
      if (resetError) {
        setError(resetError.message);
        return;
      }
      setNotice(`A password recovery link was sent to ${email}.`);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Unable to send the recovery email.');
    } finally {
      setSending(false);
    }
  }

  return <>
    <header className="pageHeader"><div><span className="eyebrow">Account · Security</span><h1>Password security</h1><p>Change your password or request a secure recovery link for your authorized back-office account.</p></div><span className="headerStatus"><ShieldCheck size={15} />{role}</span></header>
    {notice && <div className="successMessage" role="status"><MailCheck size={16} />{notice}</div>}
    {error && <div className="successMessage errorMessage" role="alert">{error}</div>}
    <section className="grid securityGrid">
      <form className="panel" onSubmit={event => void updatePassword(event)}>
        <div className="panelHead"><div><h2>Change password</h2><p>Confirm your current password before choosing a new one.</p></div><KeyRound size={22} /></div>
        <div className="securityFields">
          <label className="fieldLabel"><span>Current password</span><input required type="password" autoComplete="current-password" value={currentPassword} onChange={event => setCurrentPassword(event.target.value)} /></label>
          <label className="fieldLabel"><span>New password</span><input required type="password" minLength={8} autoComplete="new-password" value={password} onChange={event => setPassword(event.target.value)} /></label>
          <label className="fieldLabel"><span>Confirm new password</span><input required type="password" minLength={8} autoComplete="new-password" value={confirmation} onChange={event => setConfirmation(event.target.value)} /></label>
          <button type="submit" disabled={saving || sending}>{saving ? 'Updating…' : 'Update password'}</button>
        </div>
      </form>
      <article className="panel">
        <div className="panelHead"><div><h2>Forgot your password?</h2><p>Send a one-time Supabase recovery link to your verified work email.</p></div><MailCheck size={22} /></div>
        <div className="securityRecovery"><strong>{email}</strong><p>The recovery link expires and can only be used once. Do not forward it to anyone.</p><button type="button" className="secondary" disabled={saving || sending} onClick={() => void sendRecoveryEmail()}>{sending ? 'Sending…' : 'Email recovery link'}</button></div>
      </article>
    </section>
  </>;
}
