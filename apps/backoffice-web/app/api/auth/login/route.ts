import { NextResponse } from 'next/server';
import { createSessionToken, SESSION_COOKIE, SESSION_DURATION_SECONDS, sessionCookieOptions } from '../../../lib/session';

const BACKOFFICE_ROLES = new Set(['SUPERVISOR', 'HR', 'PAYROLL', 'FINANCE', 'ADMIN', 'AUDITOR']);

type MobileLoginResponse = {
  employee?: {
    id?: string;
    organizationId?: string;
    employeeNumber?: string;
    name?: string;
    email?: string;
    role?: string;
  };
};

export async function POST(request: Request) {
  if (process.env.NODE_ENV === 'production' || process.env.BACKOFFICE_AUTH_MODE === 'production') {
    return NextResponse.json({ message: 'Development login is disabled. Configure the production identity provider.' }, { status: 503 });
  }

  let credentials: { username?: string; password?: string };
  try {
    credentials = await request.json() as typeof credentials;
  } catch {
    return NextResponse.json({ message: 'Invalid request.' }, { status: 400 });
  }
  if (!credentials.username || !credentials.password) {
    return NextResponse.json({ message: 'Employee ID or email and password are required.' }, { status: 400 });
  }

  const apiUrl = process.env.API_URL ?? process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000/api';
  let upstream: Response;
  try {
    upstream = await fetch(`${apiUrl}/mobile/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(credentials),
      cache: 'no-store',
    });
  } catch {
    return NextResponse.json({ message: 'Authentication service is unavailable.' }, { status: 503 });
  }
  if (!upstream.ok) {
    return NextResponse.json({ message: 'Invalid employee ID or password.' }, { status: 401 });
  }

  const data = await upstream.json() as MobileLoginResponse;
  const employee = data.employee;
  if (!employee?.id || !employee.organizationId || !employee.employeeNumber || !employee.name || !employee.email || !employee.role) {
    return NextResponse.json({ message: 'Authentication service returned an invalid identity.' }, { status: 502 });
  }
  if (!BACKOFFICE_ROLES.has(employee.role)) {
    return NextResponse.json({ message: 'This account does not have back-office access.' }, { status: 403 });
  }

  const expiresAt = Date.now() + SESSION_DURATION_SECONDS * 1000;
  const token = await createSessionToken({
    employeeId: employee.id,
    organizationId: employee.organizationId,
    employeeNumber: employee.employeeNumber,
    name: employee.name,
    email: employee.email,
    role: employee.role,
    expiresAt,
  });
  const response = NextResponse.json({ user: { name: employee.name, role: employee.role } });
  response.cookies.set(SESSION_COOKIE, token, sessionCookieOptions());
  return response;
}
