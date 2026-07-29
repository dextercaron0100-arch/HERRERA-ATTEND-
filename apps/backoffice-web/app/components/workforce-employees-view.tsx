'use client';

import { Plus, RefreshCw, Search, ShieldCheck, UserCheck, UserX, Users } from 'lucide-react';
import { FormEvent, useCallback, useEffect, useMemo, useState } from 'react';
import { apiRequest, appConfig } from '../lib/api';
import { ErrorPanel, LoadingPanel } from './feedback';

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

const roles = ['EMPLOYEE', 'SUPERVISOR', 'HR', 'PAYROLL', 'FINANCE', 'ADMIN', 'AUDITOR'] as const;
const emptyForm = { employeeNumber: '', name: '', email: '', role: 'EMPLOYEE', worksiteId: '' };

export function WorkforceEmployeesView() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [worksites, setWorksites] = useState<Worksite[]>([]);
  const [form, setForm] = useState(emptyForm);
  const [query, setQuery] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
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

  return <>
    <header className="pageHeader"><div><span className="eyebrow">Workforce · Staff access</span><h1>Employees</h1><p>Onboard staff, assign access roles and worksites, and control account availability.</p></div><div className="actions"><button type="button" className="secondary" onClick={() => void load()}><RefreshCw size={14}/>Refresh</button><button type="button" onClick={() => setShowForm(value => !value)}><Plus size={15}/>{showForm ? 'Close form' : 'Add staff member'}</button></div></header>
    {message && <div className="successMessage" role="status">{message}</div>}
    {error && employees.length > 0 && <div className="errorMessage" role="alert">{error}</div>}
    {showForm && <section className="panel" aria-labelledby="employee-form-title"><div className="panelHead"><div><h2 id="employee-form-title">Onboard staff member</h2><p>Create the workforce profile and select the minimum access the person needs.</p></div><ShieldCheck size={22}/></div><form onSubmit={submit}><div className="filters"><label className="fieldLabel"><span>Employee number</span><input required maxLength={40} value={form.employeeNumber} onChange={event => setForm({...form, employeeNumber:event.target.value})} placeholder="EMP-001"/></label><label className="fieldLabel growField"><span>Full name</span><input required maxLength={120} value={form.name} onChange={event => setForm({...form, name:event.target.value})} placeholder="Juan Dela Cruz"/></label><label className="fieldLabel growField"><span>Work email</span><input required type="email" value={form.email} onChange={event => setForm({...form, email:event.target.value})} placeholder="juan@company.com"/></label><label className="fieldLabel"><span>Access role</span><select value={form.role} onChange={event => setForm({...form, role:event.target.value})}>{roles.map(role => <option key={role} value={role}>{role === 'ADMIN' ? 'Super Admin' : role.replaceAll('_',' ')}</option>)}</select></label><label className="fieldLabel growField"><span>Primary worksite</span><select value={form.worksiteId} onChange={event => setForm({...form, worksiteId:event.target.value})}><option value="">Unassigned</option>{worksites.map(site => <option key={site.id} value={site.id}>{site.name}</option>)}</select></label><button disabled={saving} type="submit">{saving ? 'Saving…' : 'Create staff profile'}</button></div></form></section>}
    <section className="panel"><div className="panelHead"><div><h2>Staff directory</h2><p>{employees.filter(employee => employee.active).length} active · {employees.filter(employee => !employee.active).length} suspended</p></div><label className="searchField"><Search size={15}/><span className="srOnly">Search employees</span><input value={query} onChange={event => setQuery(event.target.value)} placeholder="Search people"/></label></div>{loading ? <LoadingPanel label="Loading employees…"/> : error && !employees.length ? <ErrorPanel message={error} retry={() => void load()}/> : <div className="tableWrap" tabIndex={0} role="region" aria-label="Staff directory"><table><thead><tr><th scope="col">Employee</th><th scope="col">Number</th><th scope="col">Email</th><th scope="col">Role</th><th scope="col">Worksite</th><th scope="col">Access</th><th scope="col">Action</th></tr></thead><tbody>{visible.length ? visible.map(employee => <tr key={employee.id} className={employee.active ? '' : 'mutedRow'}><td><span className="employeeCell"><span className="miniAvatar">{employee.name.split(' ').slice(0,2).map(part => part[0]).join('').toUpperCase()}</span><strong>{employee.name}</strong></span></td><td>{employee.employeeNumber}</td><td>{employee.email}</td><td><span className="pill">{employee.role === 'ADMIN' ? 'SUPER ADMIN' : employee.role}</span></td><td>{employee.worksite?.name ?? 'Unassigned'}</td><td><span className={`pill ${employee.active ? 'successPill' : 'dangerPill'}`}>{employee.active ? <UserCheck size={12}/> : <UserX size={12}/>} {employee.active ? 'Active' : 'Suspended'}</span></td><td><button type="button" className="secondary compactButton" disabled={saving} onClick={() => void setActive(employee, !employee.active)}>{employee.active ? 'Suspend' : 'Activate'}</button></td></tr>) : <tr><td colSpan={7}><div className="emptyTable"><Users size={22}/> No employees match your search.</div></td></tr>}</tbody></table></div>}</section>
  </>;
}
