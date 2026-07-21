'use client';

import { FormEvent, useState } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const router = useRouter();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitting(true);
    setError('');
    const form = new FormData(event.currentTarget);
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: form.get('username'), password: form.get('password') }),
    }).catch(() => null);
    if (!response?.ok) {
      const payload = response ? await response.json().catch(() => null) as { message?: string } | null : null;
      setError(payload?.message ?? 'Unable to sign in. Check that the API is running.');
      setSubmitting(false);
      return;
    }
    router.replace('/');
    router.refresh();
  }

  return (
    <main style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', padding: 24, background: 'linear-gradient(145deg,#f4f8ff,#fff8e7)' }}>
      <section style={{ width: 'min(100%, 430px)', padding: 32, borderRadius: 24, background: '#fff', boxShadow: '0 24px 70px rgba(13,44,88,.14)', border: '1px solid #dce6f5' }}>
        <p style={{ color: '#0b4db8', fontWeight: 800, letterSpacing: 2, margin: 0 }}>HERRERA ATTEND</p>
        <h1 style={{ margin: '12px 0 8px', fontSize: 30, color: '#10213d' }}>Welcome back</h1>
        <p style={{ margin: '0 0 24px', color: '#5b677a', lineHeight: 1.5 }}>Sign in to the back-office workspace. This login is available for local development only.</p>
        <form onSubmit={submit} style={{ display: 'grid', gap: 16 }}>
          <label style={{ display: 'grid', gap: 7, color: '#27364d', fontWeight: 650 }}>
            Employee ID or email
            <input name="username" autoComplete="username" required autoFocus placeholder="HR-001" style={{ minHeight: 46, padding: '0 13px', border: '1px solid #c9d5e6', borderRadius: 10, font: 'inherit' }} />
          </label>
          <label style={{ display: 'grid', gap: 7, color: '#27364d', fontWeight: 650 }}>
            Password
            <input name="password" type="password" autoComplete="current-password" required minLength={8} style={{ minHeight: 46, padding: '0 13px', border: '1px solid #c9d5e6', borderRadius: 10, font: 'inherit' }} />
          </label>
          {error && <p role="alert" style={{ margin: 0, color: '#b42318', background: '#fff1f0', padding: 12, borderRadius: 9 }}>{error}</p>}
          <button type="submit" disabled={submitting} style={{ minHeight: 48, border: 0, borderRadius: 11, background: '#0b5bd3', color: '#fff', font: 'inherit', fontWeight: 800, cursor: submitting ? 'wait' : 'pointer', opacity: submitting ? .7 : 1 }}>
            {submitting ? 'Signing in…' : 'Sign in'}
          </button>
        </form>
        <p style={{ margin: '20px 0 0', color: '#68758a', fontSize: 13 }}>Super Admin demo: ADMIN-001 / Herrera123!</p>
      </section>
    </main>
  );
}
