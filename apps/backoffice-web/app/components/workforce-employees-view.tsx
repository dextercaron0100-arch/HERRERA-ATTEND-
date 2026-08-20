'use client';

import { Building2, KeyRound, Plus, RefreshCw, Search, ShieldCheck, UserCheck, UserX, Users } from 'lucide-react';
import { FormEvent, useCallback, useEffect, useMemo, useState } from 'react';
import { apiRequest, appConfig } from '../lib/api';
import { ErrorPanel, LoadingPanel } from './feedback';
import { useOptionalSession } from './session-provider';

type Worksite = { id: string; name: string };
type Employee = {
  id: string;
  employeeNumber: string;
  name: string;
  email: string;
  role: string;
  active: boolean;
  worksite: Worksite | null;
  devices: { id: string }[];
};
type TemporaryCredential = { employee: Employee; password: string };

const roles = ['EMPLOYEE', 'SUPERVISOR', 'HR', 'PAYROLL', 'FINANCE', 'ADMIN', 'AUDITOR'] as const;
const emptyForm = { employeeNumber: '', name: '', email: '', role: 'EMPLOYEE', worksiteId: '' };

export function WorkforceEmployeesView() {
  const session = useOptionalSession();
  const normalizedRole = session?.role.replaceAll(' ', '_').toUpperCase();
  const [mounted, setMounted] = useState(false);
  const canResetPasswords = mounted && ['HR', 'ADMIN', 'SUPER_ADMIN'].includes(normalizedRole ?? '');
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [worksites, setWorksites] = useState<Worksite[]>([]);
  const [form, setForm] = useState(emptyForm);
  const [worksiteEmployee, setWorksiteEmployee] = useState<Employee | null>(null);
  const [selectedWorksiteId, setSelectedWorksiteId] = useState('');
  const [query, setQuery] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [resettingEmployeeId, setResettingEmployeeId] = useState<string | null>(null);
  const [temporaryCredential, setTemporaryCredential] = useState<TemporaryCredential | null>(null);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  const load = useCallback(async () => {
    setLoading(true); setError('');
    try {
      const [people, sites] = await Promise.all([
        apiRequest<Employee[]>(`/workforce/employees?organizationId=${appConfig.organizationId}&status=all`),
        apiRequest<Worksite[]>(`/workforce/worksites?organizationId=${appConfig.organizationId}`),
      ]);
      setEmployees(people); setWorksites(sites);
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to load employees.'); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { setMounted(true); }, []);
  useEffect(() => { void load(); }, [load]);
  const visible = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return employees.filter(employee => !needle || [employee.name, employee.employeeNumber, employee.email, employee.role, employee.worksite?.name ?? ''].some(value => value.toLowerCase().includes(needle)));
  }, [employees, query]);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setSaving(true); setError(''); setMessage('');
    try {
      await apiRequest('/workforce/employees', {
        method: 'POST',
        body: JSON.stringify({ organizationId: appConfig.organizationId, employeeNumber: form.employeeNumber.trim(), name: form.name.trim(), email: form.email.trim(), role: form.role, ...(form.worksiteId ? { worksiteId: form.worksiteId } : {}) }),
      });
      setForm(emptyForm); setShowForm(false); setMessage('Staff profile created successfully.'); await load();
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to add employee.'); }
    finally { setSaving(false); }
  }

  async function setActive(employee: Employee, active: boolean) {
    setSaving(true); setError(''); setMessage('');
    try {
      await apiRequest(`/workforce/employees/${employee.id}/status`, { method: 'PATCH', body: JSON.stringify({ active }) });
      setMessage(`${employee.name} has been ${active ? 'activated' : 'suspended'}.`); await load();
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to update the account.'); }
    finally { setSaving(false); }
  }

  async function sendPasswordReset(employee: Employee) {
    if (!window.confirm(`Reset the password for ${employee.name}? Their current password will stop working immediately.`)) return;
    setTemporaryCredential(null);
    setResettingEmployeeId(employee.id); setError(''); setMessage('');
    try {
      const result = await apiRequest<{ temporaryPassword: string }>(`/workforce/employees/${employee.id}/password-reset`, {
        method: 'POST',
      });
      setTemporaryCredential({ employee, password: result.temporaryPassword });
      setMessage(`A temporary password was created for ${employee.name}. Copy it now; it is only shown on this screen.`);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Unable to create a temporary password.');
    } finally {
      setResettingEmployeeId(null);
    }
  }

  async function copyTemporaryPassword() {
    if (!temporaryCredential) return;
    try {
      await navigator.clipboard.writeText(temporaryCredential.password);
      setMessage('Temporary password copied. Share it privately with the employee.');
    } catch {
      setError('Unable to copy automatically. Select and copy the temporary password manually.');
    }
  }

  function startWorksiteAssignment(employee: Employee) {
    setWorksiteEmployee(employee);
    setSelectedWorksiteId(employee.worksite?.id ?? '');
    setError('');
    setMessage('');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  async function assignWorksite(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!worksiteEmployee) return;
    setSaving(true); setError(''); setMessage('');
    try {
      await apiRequest(`/workforce/employees/${worksiteEmployee.id}/worksite`, {
        method: 'PATCH',
        body: JSON.stringify({ worksiteId: selectedWorksiteId || null }),
      });
      setMessage(selectedWorksiteId ? `${worksiteEmployee.name} has been assigned to the selected worksite.` : `${worksiteEmployee.name} is now unassigned.`);
      setWorksiteEmployee(null); setSelectedWorksiteId(''); await load();
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to update the worksite assignment.'); }
    finally { setSaving(false); }
  }

  function canResetEmployeePassword(employee: Employee) {
    if (!canResetPasswords || employee.id === session?.employeeId) return false;
    return !(normalizedRole === 'HR' && employee.role === 'ADMIN');
  }

  return <>
    <header className="pageHeader"><div><span className="eyebrow">Workforce · Staff access</span><h1>Employees</h1><p>Onboard staff, assign access roles and worksites, and control account availability.</p></div><div className="actions"><button type="button" className="secondary" onClick={() => void load()}><RefreshCw size={14}/>Refresh</button><button type="button" onClick={() => setShowForm(value => !value)}><Plus size={15}/>{showForm ? 'Close form' : 'Add staff member'}</button></div></header>
    {message && <div className="successMessage" role="status">{message}</div>}
    {error && employees.length > 0 && <div className="errorMessage" role="alert">{error}</div>}
    {showForm && <section className="panel" aria-labelledby="employee-form-title"><div className="panelHead"><div><h2 id="employee-form-title">Onboard staff member</h2><p>Create the workforce profile and select the minimum access the person needs.</p></div><ShieldCheck size={22}/></div><form onSubmit={submit}><div className="filters"><label className="fieldLabel"><span>Employee number</span><input required maxLength={40} value={form.employeeNumber} onChange={event => setForm({...form, employeeNumber:event.target.value})} placeholder="EMP-001"/></label><label className="fieldLabel growField"><span>Full name</span><input required maxLength={120} value={form.name} onChange={event => setForm({...form, name:event.target.value})} placeholder="Juan Dela Cruz"/></label><label className="fieldLabel growField"><span>Work email</span><input required type="email" value={form.email} onChange={event => setForm({...form, email:event.target.value})} placeholder="juan@company.com"/></label><label className="fieldLabel"><span>Access role</span><select value={form.role} onChange={event => setForm({...form, role:event.target.value})}>{roles.map(role => <option key={role} value={role}>{role === 'ADMIN' ? 'Super Admin' : role.replaceAll('_',' ')}</option>)}</select></label><label className="fieldLabel growField"><span>Primary worksite</span><select value={form.worksiteId} onChange={event => setForm({...form, worksiteId:event.target.value})}><option value="">Unassigned</option>{worksites.map(site => <option key={site.id} value={site.id}>{site.name}</option>)}</select></label><button disabled={saving} type="submit">{saving ? 'Saving…' : 'Create staff profile'}</button></div></form></section>}
    {worksiteEmployee && <section className="panel" aria-labelledby="worksite-assignment-title"><div className="panelHead"><div><h2 id="worksite-assignment-title">Assign worksite</h2><p>Choose the mobile login and attendance location for {worksiteEmployee.name}.</p></div><Building2 size={22}/></div><form onSubmit={assignWorksite}><div className="filters"><label className="fieldLabel growField"><span>Employee</span><input disabled value={`${worksiteEmployee.employeeNumber} — ${worksiteEmployee.name}`}/></label><label className="fieldLabel growField"><span>Primary worksite</span><select value={selectedWorksiteId} onChange={event => setSelectedWorksiteId(event.target.value)}><option value="">Unassigned</option>{worksites.map(site => <option key={site.id} value={site.id}>{site.name}</option>)}</select></label><button disabled={saving} type="submit">{saving ? 'Saving…' : 'Save assignment'}</button><button type="button" className="secondary" disabled={saving} onClick={() => setWorksiteEmployee(null)}>Cancel</button></div></form></section>}
    {temporaryCredential && <section className="panel temporaryCredential" aria-labelledby="temporary-password-title"><div className="panelHead"><div><h2 id="temporary-password-title">Temporary login password</h2><p>This password is shown only here. Give it privately to {temporaryCredential.employee.name}.</p></div><KeyRound size={22}/></div><div className="temporaryCredentialGrid"><label className="fieldLabel"><span>Employee email</span><input readOnly value={temporaryCredential.employee.email}/></label><label className="fieldLabel"><span>Temporary password</span><input readOnly autoComplete="off" value={temporaryCredential.password} onFocus={event => event.currentTarget.select()}/></label><div className="actions"><button type="button" onClick={() => void copyTemporaryPassword()}>Copy password</button><button type="button" className="secondary" onClick={() => setTemporaryCredential(null)}>Close</button></div></div><p className="fieldHelp">The employee signs in with this password and must create a new private password before using HERRERA ATTEND.</p></section>}
    <section className="panel"><div className="panelHead"><div><h2>Staff directory</h2><p>{employees.filter(employee => employee.active).length} active · {employees.filter(employee => !employee.active).length} suspended</p></div><label className="searchField"><Search size={15}/><span className="srOnly">Search employees</span><input value={query} onChange={event => setQuery(event.target.value)} placeholder="Search people"/></label></div>{loading ? <LoadingPanel label="Loading employees…"/> : error && !employees.length ? <ErrorPanel message={error} retry={() => void load()}/> : <div className="tableWrap" tabIndex={0} role="region" aria-label="Staff directory"><table><thead><tr><th scope="col">Employee</th><th scope="col">Number</th><th scope="col">Email</th><th scope="col">Role</th><th scope="col">Worksite</th><th scope="col">Access</th><th scope="col">Actions</th></tr></thead><tbody>{visible.length ? visible.map(employee => <tr key={employee.id} className={employee.active ? '' : 'mutedRow'}><td><span className="employeeCell"><span className="miniAvatar">{employee.name.split(' ').slice(0,2).map(part => part[0]).join('').toUpperCase()}</span><strong>{employee.name}</strong></span></td><td>{employee.employeeNumber}</td><td>{employee.email}</td><td><span className="pill">{employee.role === 'ADMIN' ? 'SUPER ADMIN' : employee.role}</span></td><td>{employee.worksite?.name ?? 'Unassigned'}</td><td><span className={`pill ${employee.active ? 'successPill' : 'dangerPill'}`}>{employee.active ? <UserCheck size={12}/> : <UserX size={12}/>} {employee.active ? 'Active' : 'Suspended'}</span></td><td><div className="rowActions"><button type="button" className="secondary compactButton" disabled={saving || resettingEmployeeId !== null} onClick={() => startWorksiteAssignment(employee)}>{employee.worksite ? 'Change worksite' : 'Assign worksite'}</button>{canResetEmployeePassword(employee) && <button type="button" className="secondary compactButton" disabled={saving || resettingEmployeeId !== null} onClick={() => void sendPasswordReset(employee)}><KeyRound size={13}/>{resettingEmployeeId === employee.id ? 'Resetting…' : 'Reset password'}</button>}<button type="button" className="secondary compactButton" disabled={saving || resettingEmployeeId !== null} onClick={() => void setActive(employee, !employee.active)}>{employee.active ? 'Suspend' : 'Activate'}</button></div></td></tr>) : <tr><td colSpan={7}><div className="emptyTable"><Users size={22}/> No employees match your search.</div></td></tr>}</tbody></table></div>}</section>
  </>;
}
