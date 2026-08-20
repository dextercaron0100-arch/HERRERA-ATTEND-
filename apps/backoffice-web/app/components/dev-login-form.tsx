'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export function DevLoginForm() {
  const router = useRouter();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(event: React.FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });
      if (!response.ok) {
        const payload = await response.json().catch(() => null) as { message?: string } | null;
        setError(payload?.message ?? 'Sign in failed.');
        return;
      }
      router.replace('/');
      router.refresh();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form className="herreraClerkCard" onSubmit={event => void onSubmit(event)}>
      <div className="herreraClerkHeader">
        <p><strong>Local development sign-in</strong></p>
        <p>No Clerk account configured — signing in with a demo employee record instead.</p>
      </div>
      <label className="herreraClerkLabel" htmlFor="dev-login-username">Employee ID or email</label>
      <input
        id="dev-login-username"
        className="herreraClerkInput"
        value={username}
        onChange={event => setUsername(event.target.value)}
        placeholder="ADMIN-001"
        autoComplete="username"
        required
      />
      <label className="herreraClerkLabel" htmlFor="dev-login-password">Password</label>
      <input
        id="dev-login-password"
        className="herreraClerkInput"
        type="password"
        value={password}
        onChange={event => setPassword(event.target.value)}
        placeholder="Herrera123!"
        autoComplete="current-password"
        required
      />
      {error && <p role="alert">{error}</p>}
      <button className="herreraClerkButton" type="submit" disabled={submitting}>
        {submitting ? 'Signing in…' : 'Sign in'}
      </button>
    </form>
  );
}
