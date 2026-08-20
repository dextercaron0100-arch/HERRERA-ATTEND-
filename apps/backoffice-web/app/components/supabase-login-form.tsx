'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '../lib/supabase/client';

export function SupabaseLoginForm({ initialError }: { initialError?: string }) {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(initialError ?? null);
  const [notice, setNotice] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(event: React.FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setError(null);
    setNotice(null);
    try {
      const { error: signInError } = await createClient().auth.signInWithPassword({
        email: email.trim().toLowerCase(),
        password,
      });
      if (signInError) {
        setError(signInError.message);
        return;
      }
      router.replace('/');
      router.refresh();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Sign in failed.');
    } finally {
      setSubmitting(false);
    }
  }

  async function requestPasswordReset() {
    if (!email.trim()) {
      setError('Enter your work email first.');
      return;
    }
    setSubmitting(true);
    setError(null);
    setNotice(null);
    try {
      const { error: resetError } = await createClient().auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        { redirectTo: `${window.location.origin}/auth/confirm?next=/reset-password` },
      );
      if (resetError) setError(resetError.message);
      else setNotice('If this account exists, a password reset link has been sent.');
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Password reset failed.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form className="herreraAuthCard" onSubmit={event => void onSubmit(event)}>
      <label className="herreraAuthLabel" htmlFor="login-email">Work email</label>
      <input
        id="login-email"
        className="herreraAuthInput"
        type="email"
        value={email}
        onChange={event => setEmail(event.target.value)}
        placeholder="name@company.com"
        autoComplete="email"
        required
      />
      <label className="herreraAuthLabel" htmlFor="login-password">Password</label>
      <input
        id="login-password"
        className="herreraAuthInput"
        type="password"
        value={password}
        onChange={event => setPassword(event.target.value)}
        autoComplete="current-password"
        required
      />
      <button className="authTextButton" type="button" disabled={submitting} onClick={() => void requestPasswordReset()}>
        Forgot password?
      </button>
      {error && <p className="authMessage authError" role="alert">{error}</p>}
      {notice && <p className="authMessage" role="status">{notice}</p>}
      <button className="herreraAuthButton" type="submit" disabled={submitting}>
        {submitting ? 'Please wait…' : 'Sign in'}
      </button>
    </form>
  );
}
