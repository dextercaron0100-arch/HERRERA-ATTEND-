import { SignIn } from '@clerk/nextjs';

export default function LoginPage() {
  return (
    <main style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', padding: 24, background: 'linear-gradient(145deg,#f4f8ff,#fff8e7)' }}>
      <section style={{ width: 'min(100%, 460px)', display: 'grid', justifyItems: 'center', gap: 22 }}>
        <div style={{ textAlign: 'center' }}>
          <p style={{ color: '#0b4db8', fontWeight: 800, letterSpacing: 2, margin: 0 }}>HERRERA ATTEND</p>
          <h1 style={{ margin: '12px 0 8px', fontSize: 30, color: '#10213d' }}>Welcome back</h1>
          <p style={{ margin: 0, color: '#5b677a', lineHeight: 1.5 }}>Secure access for authorized administrators.</p>
        </div>
        <SignIn routing="path" path="/login" forceRedirectUrl="/" signUpUrl="/login" />
      </section>
    </main>
  );
}
