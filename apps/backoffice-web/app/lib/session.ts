import { cookies } from 'next/headers';

export const SESSION_COOKIE = 'herrera_backoffice_session';
export const SESSION_DURATION_SECONDS = 8 * 60 * 60;

export type BackofficeSession = {
  employeeId: string;
  organizationId: string;
  employeeNumber: string;
  name: string;
  email: string;
  role: string;
  expiresAt: number;
};

const encoder = new TextEncoder();

function sessionSecret() {
  const configured = process.env.BACKOFFICE_SESSION_SECRET;
  if (configured) return configured;
  if (process.env.NODE_ENV !== 'production') return 'herrera-attend-local-development-session-key';
  return null;
}

function toBase64Url(value: Uint8Array | string) {
  const bytes = typeof value === 'string' ? encoder.encode(value) : value;
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/u, '');
}

function fromBase64Url(value: string) {
  const base64 = value.replaceAll('-', '+').replaceAll('_', '/').padEnd(Math.ceil(value.length / 4) * 4, '=');
  const binary = atob(base64);
  return new Uint8Array(Array.from(binary, (character) => character.charCodeAt(0)));
}

async function signature(payload: string, secret: string) {
  const key = await crypto.subtle.importKey('raw', encoder.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return toBase64Url(new Uint8Array(await crypto.subtle.sign('HMAC', key, encoder.encode(payload))));
}

export async function createSessionToken(session: BackofficeSession) {
  const secret = sessionSecret();
  if (!secret) throw new Error('BACKOFFICE_SESSION_SECRET is required in production');
  const payload = toBase64Url(JSON.stringify(session));
  return `${payload}.${await signature(payload, secret)}`;
}

export async function verifySessionToken(token: string | undefined): Promise<BackofficeSession | null> {
  const secret = sessionSecret();
  if (!secret || !token) return null;
  const [payload, suppliedSignature, extra] = token.split('.');
  if (!payload || !suppliedSignature || extra) return null;
  const expectedSignature = await signature(payload, secret);
  const suppliedBytes = encoder.encode(suppliedSignature);
  const expectedBytes = encoder.encode(expectedSignature);
  if (suppliedBytes.length !== expectedBytes.length) return null;
  let difference = 0;
  for (let index = 0; index < suppliedBytes.length; index += 1) difference |= suppliedBytes[index] ^ expectedBytes[index];
  if (difference !== 0) return null;
  try {
    const session = JSON.parse(new TextDecoder().decode(fromBase64Url(payload))) as BackofficeSession;
    if (!session.employeeId || !session.organizationId || !session.role || session.expiresAt <= Date.now()) return null;
    return session;
  } catch {
    return null;
  }
}

export async function getSession() {
  const store = await cookies();
  return verifySessionToken(store.get(SESSION_COOKIE)?.value);
}

export function sessionCookieOptions() {
  return {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax' as const,
    path: '/',
    maxAge: SESSION_DURATION_SECONDS,
  };
}
