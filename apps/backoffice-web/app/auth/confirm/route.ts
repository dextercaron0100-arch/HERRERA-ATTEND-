import { NextResponse } from 'next/server';
import type { EmailOtpType } from '@supabase/supabase-js';
import { createClient } from '../../lib/supabase/server';

const EMAIL_OTP_TYPES = new Set<EmailOtpType>([
  'email',
  'email_change',
  'invite',
  'magiclink',
  'recovery',
  'signup',
]);

export async function GET(request: Request) {
  const url = new URL(request.url);
  const code = url.searchParams.get('code');
  const tokenHash = url.searchParams.get('token_hash');
  const rawType = url.searchParams.get('type');
  const requestedNext = url.searchParams.get('next');
  const next = requestedNext?.startsWith('/') && !requestedNext.startsWith('//')
    ? requestedNext
    : '/';

  if (code || (tokenHash && rawType && EMAIL_OTP_TYPES.has(rawType as EmailOtpType))) {
    const supabase = await createClient();
    const { error } = code
      ? await supabase.auth.exchangeCodeForSession(code)
      : await supabase.auth.verifyOtp({
          token_hash: tokenHash!,
          type: rawType as EmailOtpType,
        });
    if (!error) {
      return NextResponse.redirect(new URL(next, url.origin), {
        headers: { 'Cache-Control': 'private, no-store' },
      });
    }
  }

  const loginUrl = new URL('/login', url.origin);
  loginUrl.searchParams.set('error', 'The authentication link is invalid or expired.');
  return NextResponse.redirect(loginUrl);
}
