'use client';

import { Plus, RefreshCw, Search, Users } from 'lucide-react';
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
  worksite: Worksite | null;
  department: { name: string } | null;
};

const emptyForm = { employeeNumber: '', name: '', email: '', worksiteId: '' };

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
        apiRequest<Employee[]>(`/workforce/employees?organizationId=${appConfig.organizationId}`),
        apiRequest<Worksite[]>(`/workforce/worksites?organizationId=${appConfig.organizationId}`),
      ]);
      setEmployees(people); setWorksites(sites);
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to load employees.'); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { void load(); }, [load]);
  const visible = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return employees.filter(employee => !needle || [employee.name, employee.employeeNumber, employee.email, employee.worksite?.name ?? ''].some(value => value.toLowerCase().includes(needle)));
  }, [employees, query]);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setSaving(true); setError(''); setMessage('');
    try {
      await apiRequest('/workforce/employees', {
        method: 'POST',
        body: JSON.stringify({ organizationId: appConfig.organizationId, employeeNumber: form.employeeNumber.trim(), name: form.name.trim(), email: form.email.trim(), ...(form.worksiteId ? { worksiteId: form.worksiteId } : {}) }),
      });
      setForm(emptyForm); setShowForm(false); setMessage('Employee added successfully.'); await load();
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to add employee.'); }
    finally { setSaving(false); }
  }

  return <>
    <header className="pageHeader"><div><span className="eyebrow">Workforce · People directory</span><h1>Employees</h1><p>Add employees, assign their primary worksite, and find workforce records quickly.</p></div><div className="actions"><button type="button" className="secondary" onClick={() => void load()}><RefreshCw size={14}/>Refresh</button><button type="button" onClick={() => setShowForm(value => !value)}><Plus size={15}/>{showForm ? 'Close form' : 'Add employee'}</button></div></header>
    {message && <div className="successMessage" role="status">{message}</div>}
    {showForm && <section className="panel" aria-labelledby="employee-form-title"><div className="panelHead"><div><h2 id="employee-form-title">New employee</h2><p>All fields except worksite are required.</p></div></div><form onSubmit={submit}><div className="filters"><label className="fieldLabel"><span>Employee number</span><input required maxLength={40} value={form.employeeNumber} onChange={event => setForm({...form, employeeNumber:event.target.value})} placeholder="EMP-001"/></label><label className="fieldLabel growField"><span>Full name</span><input required maxLength={120} value={form.name} onChange={event => setForm({...form, name:event.target.value})} placeholder="Juan Dela Cruz"/></label><label className="fieldLabel growField"><span>Work email</span><input required type="email" value={form.email} onChange={event => setForm({...form, email:event.target.value})} placeholder="juan@company.com"/></label><label className="fieldLabel growField"><span>Primary worksite</span><select value={form.worksiteId} onChange={event => setForm({...form, worksiteId:event.target.value})}><option value="">Unassigned</option>{worksites.map(site => <option key={site.id} value={site.id}>{site.name}</option>)}</select></label><button disabled={saving} type="submit">{saving ? 'Saving…' : 'Save employee'}</button></div></form></section>}
    <section className="panel"><div className="panelHead"><div><h2>Employee directory</h2><p>{employees.length} active employee{employees.length === 1 ? '' : 's'}</p></div><label className="searchField"><Search size={15}/><span className="srOnly">Search employees</span><input value={query} onChange={event => setQuery(event.target.value)} placeholder="Search people"/></label></div>{loading ? <LoadingPanel label="Loading employees…"/> : error && !employees.length ? <ErrorPanel message={error} retry={() => void load()}/> : <div className="tableWrap" tabIndex={0} role="region" aria-label="Employee directory"><table><thead><tr><th scope="col">Employee</th><th scope="col">Number</th><th scope="col">Email</th><th scope="col">Role</th><th scope="col">Worksite</th><th scope="col">Department</th></tr></thead><tbody>{visible.length ? visible.map(employee => <tr key={employee.id}><td><span className="employeeCell"><span className="miniAvatar">{employee.name.split(' ').slice(0,2).map(part => part[0]).join('').toUpperCase()}</span><strong>{employee.name}</strong></span></td><td>{employee.employeeNumber}</td><td>{employee.email}</td><td><span className="pill">{employee.role}</span></td><td>{employee.worksite?.name ?? 'Unassigned'}</td><td>{employee.department?.name ?? 'Unassigned'}</td></tr>) : <tr><td colSpan={6}><div className="emptyTable"><Users size={22}/> No employees match your search.</div></td></tr>}</tbody></table></div>}</section>
  </>;
}
