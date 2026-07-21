import { SignIn } from '@clerk/nextjs';
import { CalendarCheck, CheckCircle2, LockKeyhole, MapPinCheck, ShieldCheck } from 'lucide-react';

const benefits = [
  { icon: MapPinCheck, title: 'Verified attendance', detail: 'Review location-backed time records with confidence.' },
  { icon: CalendarCheck, title: 'One operations workspace', detail: 'Manage schedules, approvals, payroll, and reports.' },
  { icon: ShieldCheck, title: 'Protected admin access', detail: 'Secure sessions keep workforce information private.' },
];

export default function LoginPage() {
  return (
    <main className="loginPage">
      <div className="loginGlow loginGlowOne" />
      <div className="loginGlow loginGlowTwo" />
      <section className="loginShell">
        <aside className="loginStory" aria-label="Herrera Attend introduction">
          <div className="loginBrand">
            <span className="loginBrandMark"><CalendarCheck size={25} strokeWidth={2.2} /></span>
            <span><strong>HERRERA</strong><small>ATTEND</small></span>
          </div>

          <div className="loginStoryCopy">
            <span className="loginEyebrow"><span /> WORKFORCE OPERATIONS</span>
            <h1>Every workday,<br /><em>clearly accounted for.</em></h1>
            <p>Accurate attendance and payroll tools for teams that value trust, clarity, and a smoother workday.</p>
          </div>

          <div className="loginBenefits">
            {benefits.map(({ icon: Icon, title, detail }, index) => (
              <article key={title} style={{ '--login-delay': `${120 + index * 80}ms` } as React.CSSProperties}>
                <span><Icon size={18} /></span>
                <div><strong>{title}</strong><p>{detail}</p></div>
              </article>
            ))}
          </div>

          <p className="loginAssurance"><CheckCircle2 size={15} /> Built for Herrera teams in the Philippines</p>
        </aside>

        <section className="loginAccess" aria-labelledby="login-title">
          <div className="loginMobileBrand">
            <span className="loginBrandMark"><CalendarCheck size={21} /></span>
            <span><strong>HERRERA</strong><small>ATTEND</small></span>
          </div>
          <div className="loginAccessHead">
            <span className="loginLock"><LockKeyhole size={20} /></span>
            <div>
              <span className="loginEyebrow">SECURE BACK OFFICE</span>
              <h2 id="login-title">Welcome back</h2>
              <p>Sign in with your authorized administrator account.</p>
            </div>
          </div>

          <SignIn
            routing="path"
            path="/login"
            forceRedirectUrl="/"
            withSignUp={false}
            appearance={{
              variables: {
                colorPrimary: '#075bd8',
                borderRadius: '12px',
                fontFamily: 'var(--font-geist), ui-sans-serif, system-ui, sans-serif',
              },
              elements: {
                rootBox: 'herreraClerkRoot',
                cardBox: 'herreraClerkCardBox',
                card: 'herreraClerkCard',
                header: 'herreraClerkHeader',
                socialButtonsBlockButton: 'herreraClerkSocialButton',
                socialButtonsBlockButtonText: 'herreraClerkSocialText',
                dividerLine: 'herreraClerkDivider',
                dividerText: 'herreraClerkDividerText',
                formFieldLabel: 'herreraClerkLabel',
                formFieldInput: 'herreraClerkInput',
                formButtonPrimary: 'herreraClerkButton',
                footer: 'herreraClerkFooter',
                identityPreview: 'herreraClerkIdentity',
              },
            }}
          />

          <div className="loginHelp">
            <ShieldCheck size={16} />
            <p><strong>Having trouble signing in?</strong><span>Contact your Herrera system administrator.</span></p>
          </div>
        </section>
      </section>
      <footer className="loginFooter">© 2026 Herrera Attend · Secure workforce operations</footer>
    </main>
  );
}
