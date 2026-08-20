'use client';

import { FormEvent, useCallback, useEffect, useState } from 'react';
import { LocateFixed, MapPin, Pencil, Plus, RefreshCw } from 'lucide-react';
import { apiRequest, appConfig } from '../lib/api';
import { ErrorPanel, LoadingPanel } from './feedback';
import { ManualWorksiteMap } from './manual-worksite-map';

type Worksite = {
  id: string;
  name: string;
  latitude: number | string;
  longitude: number | string;
  radiusMeters: number;
  maxAccuracyMeters: number;
};

type WorksiteForm = {
  name: string;
  latitude: string;
  longitude: string;
  radiusMeters: string;
  maxAccuracyMeters: string;
};

const emptyForm: WorksiteForm = { name: '', latitude: '', longitude: '', radiusMeters: '100', maxAccuracyMeters: '50' };

export function WorkforceWorksitesView() {
  const [rows, setRows] = useState<Worksite[]>([]);
  const [form, setForm] = useState<WorksiteForm>(emptyForm);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [locating, setLocating] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      setRows(await apiRequest<Worksite[]>(`/workforce/worksites?organizationId=${appConfig.organizationId}`));
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Unable to load worksites.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  function closeForm() {
    setForm(emptyForm);
    setEditingId(null);
    setShowForm(false);
    setError('');
  }

  function startEdit(site: Worksite) {
    setForm({
      name: site.name,
      latitude: String(site.latitude),
      longitude: String(site.longitude),
      radiusMeters: String(site.radiusMeters),
      maxAccuracyMeters: String(site.maxAccuracyMeters),
    });
    setEditingId(site.id);
    setShowForm(true);
    setError('');
    setMessage('');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function setMapLocation(latitude: number, longitude: number) {
    setForm(current => ({ ...current, latitude: latitude.toFixed(7), longitude: longitude.toFixed(7) }));
  }

  function useCurrentLocation() {
    if (!navigator.geolocation) {
      setError('This browser cannot provide a current location. Click the map or enter coordinates manually.');
      return;
    }
    setLocating(true);
    setError('');
    navigator.geolocation.getCurrentPosition(
      position => {
        setMapLocation(position.coords.latitude, position.coords.longitude);
        setLocating(false);
      },
      () => {
        setError('Current location was unavailable. Allow location access, click the map, or enter coordinates manually.');
        setLocating(false);
      },
      { enableHighAccuracy: true, timeout: 12_000 },
    );
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSaving(true);
    setError('');
    setMessage('');
    const payload = {
      organizationId: appConfig.organizationId,
      name: form.name.trim(),
      latitude: Number(form.latitude),
      longitude: Number(form.longitude),
      radiusMeters: Number(form.radiusMeters),
      maxAccuracyMeters: Number(form.maxAccuracyMeters),
    };
    try {
      await apiRequest(editingId ? `/workforce/worksites/${editingId}` : '/workforce/worksites', {
        method: editingId ? 'PATCH' : 'POST',
        body: JSON.stringify(payload),
      });
      const successMessage = editingId ? 'Worksite updated successfully.' : 'Worksite added successfully.';
      closeForm();
      setMessage(successMessage);
      await load();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : `Unable to ${editingId ? 'update' : 'add'} worksite.`);
    } finally {
      setSaving(false);
    }
  }

  return <>
    <header className="pageHeader">
      <div><span className="eyebrow">Workforce · Location management</span><h1>Worksites</h1><p>Set the exact map location and range where assigned employees may sign in and clock attendance.</p></div>
      <div className="actions"><button type="button" className="secondary" onClick={() => void load()}><RefreshCw size={14} />Refresh</button><button type="button" onClick={() => showForm ? closeForm() : setShowForm(true)}><Plus size={15} />{showForm ? 'Close form' : 'Add worksite'}</button></div>
    </header>

    {message && <div className="successMessage" role="status">{message}</div>}
    {error && (rows.length > 0 || showForm) && <div className="successMessage errorMessage" role="alert">{error}</div>}

    {showForm && <section className="panel" aria-labelledby="worksite-form-title">
      <div className="panelHead"><div><h2 id="worksite-form-title">{editingId ? 'Edit worksite range' : 'New worksite'}</h2><p>Click the map, use your current location, or enter decimal coordinates. The radius is enforced during mobile sign-in.</p></div></div>
      <form onSubmit={submit}>
        <div className="worksiteEditor">
          <ManualWorksiteMap latitude={form.latitude} longitude={form.longitude} radiusMeters={form.radiusMeters} onLocationChange={setMapLocation} />
          <div className="worksiteFields">
            <label className="fieldLabel"><span>Worksite name</span><input required maxLength={120} value={form.name} onChange={event => setForm({ ...form, name: event.target.value })} placeholder="Herrera Main Office" /></label>
            <div className="coordinateFields">
              <label className="fieldLabel"><span>Latitude</span><input required type="number" step="any" min="-90" max="90" value={form.latitude} onChange={event => setForm({ ...form, latitude: event.target.value })} placeholder="14.5995" /></label>
              <label className="fieldLabel"><span>Longitude</span><input required type="number" step="any" min="-180" max="180" value={form.longitude} onChange={event => setForm({ ...form, longitude: event.target.value })} placeholder="120.9842" /></label>
            </div>
            <button className="secondary locationButton" disabled={locating} type="button" onClick={useCurrentLocation}><LocateFixed size={15} />{locating ? 'Locating…' : 'Use my current location'}</button>
            <label className="fieldLabel"><span>Mobile login & clock-in radius (m)</span><input required type="number" min="1" max="5000" value={form.radiusMeters} onChange={event => setForm({ ...form, radiusMeters: event.target.value })} /></label>
            <label className="fieldLabel"><span>Maximum GPS error (m)</span><input required type="number" min="1" max="1000" value={form.maxAccuracyMeters} onChange={event => setForm({ ...form, maxAccuracyMeters: event.target.value })} /></label>
            <p className="fieldHelp">Mobile sign-in is denied when the employee is outside the blue radius or the device GPS error is above the maximum.</p>
          </div>
        </div>
        <div className="formActions"><button type="button" className="secondary" onClick={closeForm}>Cancel</button><button disabled={saving} type="submit">{saving ? 'Saving…' : editingId ? 'Save changes' : 'Save worksite'}</button></div>
      </form>
    </section>}

    <section className="panel">
      <div className="panelHead"><div><h2>Registered worksites</h2><p>{rows.length} approved location{rows.length === 1 ? '' : 's'}</p></div></div>
      {loading ? <LoadingPanel label="Loading worksites…" /> : error && !rows.length ? <ErrorPanel message={error} retry={() => void load()} /> : <div className="tableWrap" tabIndex={0} role="region" aria-label="Registered worksites">
        <table><thead><tr><th scope="col">Worksite</th><th scope="col">Coordinates</th><th scope="col">Mobile range</th><th scope="col">GPS accuracy limit</th><th scope="col">Status</th><th scope="col">Actions</th></tr></thead>
          <tbody>{rows.length ? rows.map(site => <tr key={site.id}><td><span className="employeeCell"><span className="miniAvatar"><MapPin size={13} /></span><strong>{site.name}</strong></span></td><td>{Number(site.latitude).toFixed(6)}, {Number(site.longitude).toFixed(6)}</td><td>{site.radiusMeters} m</td><td>{site.maxAccuracyMeters} m</td><td><span className="pill">Active</span></td><td><button type="button" className="secondary compactButton" onClick={() => startEdit(site)}><Pencil size={13} />Edit range</button></td></tr>) : <tr><td colSpan={6}><div className="emptyTable">No worksites yet. Add your first approved location above.</div></td></tr>}</tbody>
        </table>
      </div>}
    </section>
  </>;
}
