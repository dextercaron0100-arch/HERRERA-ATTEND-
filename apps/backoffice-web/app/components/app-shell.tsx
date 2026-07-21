'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useRef, useState } from 'react';
import {
  Building2,
  CalendarCheck,
  CircleGauge,
  ClipboardCheck,
  FileChartColumn,
  HelpCircle,
  Menu,
  PhilippinePeso,
  ShieldAlert,
  TestTubeDiagonal,
  UserRoundCog,
  Users,
  WalletCards,
  SlidersHorizontal,
  X,
} from 'lucide-react';
import { apiRequest, appConfig } from '../lib/api';
import { NotificationCenter } from './notification-center';
import { LogoutButton } from './logout-button';
import { useSession } from './session-provider';

const navigation = [
  {
    label: 'Workforce',
    items: [
      { label: 'Overview', href: '/', icon: CircleGauge },
      { label: 'Employees', href: '/employees', icon: UserRoundCog },
      { label: 'Worksites', href: '/worksites', icon: Building2 },
      { label: 'Attendance', href: '/attendance', icon: CalendarCheck },
      { label: 'Exceptions', href: '/exceptions', icon: ShieldAlert },
      { label: 'Approvals', href: '/approvals', icon: ClipboardCheck },
    ],
  },
  {
    label: 'Finance',
    items: [
      { label: 'Payroll', href: '/payroll', icon: PhilippinePeso },
      { label: 'Compensation', href: '/compensation', icon: WalletCards },
      { label: 'Payroll policies', href: '/payroll-policies', icon: SlidersHorizontal },
      { label: 'Reports', href: '/reports', icon: FileChartColumn },
    ],
  },
  {
    label: 'System',
    items: [{ label: 'Pilot control', href: '/pilot', icon: TestTubeDiagonal }],
  },
] as const;

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const session = useSession();
  const [menuOpen, setMenuOpen] = useState(false);
  const [navCounts, setNavCounts] = useState<Record<string, number>>({});
  const menuButtonRef = useRef<HTMLButtonElement>(null);
  const closeButtonRef = useRef<HTMLButtonElement>(null);
  const currentPageLabel = (() => {
    for (const group of navigation) {
      for (const item of group.items) {
        const isCurrent = item.href === '/'
          ? pathname === '/'
          : pathname === item.href || pathname.startsWith(`${item.href}/`);
        if (isCurrent) return item.label;
      }
    }
    return 'HERRERA ATTEND';
  })();

  useEffect(() => setMenuOpen(false), [pathname]);
  useEffect(() => {
    if (!menuOpen) return;

    closeButtonRef.current?.focus();
    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setMenuOpen(false);
        menuButtonRef.current?.focus();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [menuOpen]);
  useEffect(() => {
    let active = true;
    Promise.all([
      apiRequest<unknown[]>(`/attendance/exceptions?organizationId=${appConfig.organizationId}&status=OPEN`),
      apiRequest<unknown[]>(`/requests?organizationId=${appConfig.organizationId}&status=PENDING`),
    ]).then(([exceptions, approvals]) => {
      if (active) setNavCounts({ '/exceptions': exceptions.length, '/approvals': approvals.length });
    }).catch(() => {
      if (active) setNavCounts({});
    });
    return () => { active = false; };
  }, [pathname]);

  return (
    <div className="appShell" data-navigation-state={menuOpen ? 'open' : 'closed'}>
      <a className="skipLink" href="#main-content">Skip to main content</a>
      <header className="mobileHeader">
        <Brand />
        <button
          ref={menuButtonRef}
          className="iconButton mobileMenuButton"
          type="button"
          aria-label="Open navigation"
          aria-controls="primary-sidebar"
          aria-expanded={menuOpen}
          onClick={() => setMenuOpen(true)}
        >
          <Menu size={22} />
        </button>
      </header>
      {menuOpen && (
        <button
          type="button"
          className="navBackdrop"
          aria-label="Close navigation"
          onClick={() => {
            setMenuOpen(false);
            menuButtonRef.current?.focus();
          }}
        />
      )}
      <aside
        id="primary-sidebar"
        className={menuOpen ? 'sidebar sidebarOpen' : 'sidebar'}
        data-state={menuOpen ? 'open' : 'closed'}
      >
        <div className="sidebarTop">
          <Brand />
          <button
            ref={closeButtonRef}
            className="iconButton closeNav"
            type="button"
            aria-label="Close navigation"
            onClick={() => {
              setMenuOpen(false);
              menuButtonRef.current?.focus();
            }}
          >
            <X size={20} />
          </button>
        </div>
        <nav className="primaryNav" aria-label="Primary navigation">
          {navigation.map((group) => (
            <div className="navGroup" key={group.label}>
              <p className="navLabel">{group.label}</p>
              {group.items.map(({ label, href, icon: Icon }) => {
                const active = href === '/' ? pathname === '/' : pathname === href || pathname.startsWith(`${href}/`);
                const count = navCounts[href] ?? 0;
                return (
                  <Link
                    className={active ? 'navLink active' : 'navLink'}
                    href={href}
                    key={href}
                    aria-current={active ? 'page' : undefined}
                    data-active={active ? 'true' : 'false'}
                  >
                    <span className="navIcon" aria-hidden="true"><Icon size={18} strokeWidth={1.9} /></span>
                    <span className="navLinkLabel">{label}</span>
                    {count > 0 && <span className="navCount" aria-label={`${count} pending items`}>{count}</span>}
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>
        <div className="sidebarFooter">
          <Link className="sidebarHelp" href="/reports">
            <HelpCircle size={18} />
            <div><strong>Need help?</strong><span>Open operations reports</span></div>
          </Link>
          <div className="profileCard">
            <span className="avatar">{session.name.split(' ').map(part => part[0]).slice(0,2).join('')}</span>
            <span className="profileText"><strong>{session.name}</strong><small>{session.role}</small></span>
          </div>
          <LogoutButton />
        </div>
      </aside>
      <div className="workspace">
        <div className="topbar">
          <div className="topbarContext">
            <span className="topbarEyebrow">Back office</span>
            <strong className="topbarPageTitle">{currentPageLabel}</strong>
          </div>
          <div className="connection" role="status"><span aria-hidden="true" /> All systems operational</div>
          <div className="topbarActions">
            <NotificationCenter />
            <div className="topbarDivider" />
            <span className="topbarAvatar"><Users size={17} /></span>
            <div className="topbarUser"><strong>{session.name}</strong><small>{session.role}</small></div>
          </div>
        </div>
        <main id="main-content" tabIndex={-1}>{children}</main>
      </div>
    </div>
  );
}

function Brand() {
  return (
    <Link className="brand" href="/" aria-label="HERRERA ATTEND home">
      <span className="brandMark"><CalendarCheck size={20} /></span>
      <span><strong>HERRERA</strong><small>ATTEND</small></span>
    </Link>
  );
}
