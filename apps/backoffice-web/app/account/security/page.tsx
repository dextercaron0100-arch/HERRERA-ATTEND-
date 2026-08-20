import { createClient } from '../../lib/supabase/server';
import { AccountSecurityForm } from './account-security-form';

type LinkedEmployee = { email: string; role: string };

export default async function AccountSecurityPage() {
  const supabase = await createClient();
  const { data } = await supabase.auth.getSession();
  const accessToken = data.session?.access_token;
  if (!accessToken) return <AccessRestricted message="Sign in again to manage your password." />;

  const apiUrl = (process.env.API_URL ?? process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000/api').replace(/\/$/u, '');
  const response = await fetch(`${apiUrl}/workforce/session`, {
    headers: { authorization: `Bearer ${accessToken}` },
    cache: 'no-store',
  });
  if (!response.ok) return <AccessRestricted message="Your employee account could not be verified." />;

  const payload = await response.json() as { employee?: LinkedEmployee };
  const employee = payload.employee;
  const role = employee?.role.replaceAll(' ', '_').toUpperCase();
  if (!employee || !role || !['HR', 'ADMIN', 'SUPER_ADMIN'].includes(role)) {
    return <AccessRestricted message="Password management in the web back office is available to HR and Super Admin accounts." />;
  }

  return <AccountSecurityForm email={employee.email} role={formatRole(employee.role)} />;
}

function AccessRestricted({ message }: { message: string }) {
  return <section className="statePanel"><span className="stateIcon" aria-hidden="true">!</span><h1>Access restricted</h1><p>{message}</p></section>;
}

function formatRole(role: string) {
  if (role === 'ADMIN' || role === 'SUPER_ADMIN') return 'Super Admin';
  return role.replaceAll('_', ' ').toLowerCase().replace(/\b\w/gu, character => character.toUpperCase());
}
