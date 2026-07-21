export const appConfig = {
  apiUrl: process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000/api',
  organizationId: process.env.NEXT_PUBLIC_ORGANIZATION_ID ?? '5e80ccd3-7b82-495f-a511-db88914085c2',
  hrActorId: process.env.NEXT_PUBLIC_HR_ACTOR_ID ?? 'b9336ab3-e69b-40b0-a664-3ff6cb553879',
  supervisorActorId: process.env.NEXT_PUBLIC_SUPERVISOR_ACTOR_ID ?? 'c0979bcf-adf3-4c8c-a79a-047c5bb1bde3',
  payrollActorId: process.env.NEXT_PUBLIC_PAYROLL_ACTOR_ID ?? '653822e1-d19b-4b0b-990b-16bb3eea6fad',
  financeActorId: process.env.NEXT_PUBLIC_FINANCE_ACTOR_ID ?? '62fe878b-cf3d-498b-956d-51a1dc1baa11',
};

type TokenProvider = () => Promise<string | null>;
let tokenProvider: TokenProvider | null = null;

export function setApiTokenProvider(provider: TokenProvider | null) {
  tokenProvider = provider;
}

export async function apiRequest<T>(path: string, init?: RequestInit): Promise<T> {
  const token = await tokenProvider?.();
  const response = await fetch(`${appConfig.apiUrl}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init?.headers,
    },
  });
  if (!response.ok) {
    const payload = await response.json().catch(() => null) as { message?: string | string[] } | null;
    const message = Array.isArray(payload?.message) ? payload.message.join(', ') : payload?.message;
    throw new Error(message || `Request failed (${response.status})`);
  }
  return response.json() as Promise<T>;
}

export function formatDate(value: string) {
  return new Intl.DateTimeFormat('en-PH', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Manila' }).format(new Date(value));
}

export function formatMoney(value: number | string) {
  return new Intl.NumberFormat('en-PH', { style: 'currency', currency: 'PHP' }).format(Number(value));
}
