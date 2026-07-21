'use client';

import Link from 'next/link';
import { useCallback, useEffect, useRef, useState } from 'react';
import { Bell, CheckCheck, CircleAlert, Inbox, RefreshCw } from 'lucide-react';
import { apiRequest } from '../lib/api';
import { useSession } from './session-provider';

type NotificationItem = {
  id: string;
  title: string;
  body: string;
  type: string;
  metadata?: { requestId?: string };
  readAt: string | null;
  createdAt: string;
};

type NotificationResponse = { items: NotificationItem[]; unreadCount: number };

export function NotificationCenter() {
  const session = useSession();
  const [open, setOpen] = useState(false);
  const [data, setData] = useState<NotificationResponse>({ items: [], unreadCount: 0 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const containerRef = useRef<HTMLDivElement>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      setData(await apiRequest<NotificationResponse>(`/notifications?organizationId=${session.organizationId}&actorId=${session.employeeId}&employeeId=${session.employeeId}&limit=30`));
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Unable to load notifications');
    } finally {
      setLoading(false);
    }
  }, [session.employeeId, session.organizationId]);

  useEffect(() => { void load(); }, [load]);
  useEffect(() => {
    if (!open) return;
    const close = (event: MouseEvent | KeyboardEvent) => {
      if (event instanceof KeyboardEvent && event.key === 'Escape') setOpen(false);
      if (event instanceof MouseEvent && !containerRef.current?.contains(event.target as Node)) setOpen(false);
    };
    document.addEventListener('keydown', close);
    document.addEventListener('mousedown', close);
    return () => { document.removeEventListener('keydown', close); document.removeEventListener('mousedown', close); };
  }, [open]);

  async function read(item: NotificationItem) {
    if (!item.readAt) {
      await apiRequest(`/notifications/${item.id}/read`, { method: 'PATCH', body: JSON.stringify(identity(session)) });
      setData(current => ({
        unreadCount: Math.max(0, current.unreadCount - 1),
        items: current.items.map(row => row.id === item.id ? { ...row, readAt: new Date().toISOString() } : row),
      }));
    }
    setOpen(false);
  }

  async function readAll() {
    await apiRequest('/notifications/read-all', { method: 'POST', body: JSON.stringify(identity(session)) });
    setData(current => ({ unreadCount: 0, items: current.items.map(item => ({ ...item, readAt: item.readAt ?? new Date().toISOString() })) }));
  }

  return <div className="notificationCenter" ref={containerRef}>
    <button className="iconButton notificationButton" type="button" aria-label={`Notifications, ${data.unreadCount} unread`} aria-haspopup="dialog" aria-expanded={open} onClick={() => setOpen(value => !value)}>
      <Bell size={19}/>{data.unreadCount > 0 && <span>{data.unreadCount > 99 ? '99+' : data.unreadCount}</span>}
    </button>
    {open && <section className="notificationPanel" role="dialog" aria-label="Notifications">
      <div className="notificationHead"><div><strong>Notifications</strong><small>{data.unreadCount ? `${data.unreadCount} unread` : 'You are up to date'}</small></div><div className="notificationActions"><button type="button" aria-label="Refresh notifications" onClick={() => void load()}><RefreshCw size={15}/></button>{data.unreadCount > 0 && <button type="button" aria-label="Mark all notifications read" onClick={() => void readAll()}><CheckCheck size={15}/></button>}</div></div>
      <div className="notificationList" aria-live="polite">
        {loading ? <div className="notificationState"><RefreshCw className="spin" size={20}/>Loading notifications…</div> : error ? <div className="notificationState errorState"><CircleAlert size={20}/><span>{error}</span><button type="button" className="small" onClick={() => void load()}>Retry</button></div> : data.items.length === 0 ? <div className="notificationState"><Inbox size={24}/><strong>You&apos;re all caught up</strong><span>New approvals and updates will appear here.</span></div> : data.items.map(item => <Link href="/approvals" className={item.readAt ? 'notificationItem' : 'notificationItem unread'} key={item.id} onClick={() => void read(item)}><span className="notificationDot"/><span><strong>{item.title}</strong><small>{item.body}</small><time dateTime={item.createdAt}>{new Date(item.createdAt).toLocaleString('en-PH', { dateStyle: 'medium', timeStyle: 'short' })}</time></span></Link>)}
      </div>
    </section>}
  </div>;
}

function identity(session: ReturnType<typeof useSession>) {
  return { organizationId: session.organizationId, actorId: session.employeeId, employeeId: session.employeeId };
}
