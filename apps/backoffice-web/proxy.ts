import { NextRequest, NextResponse } from 'next/server';
import { SESSION_COOKIE, verifySessionToken } from './app/lib/session';

export async function proxy(request: NextRequest) {
  const session = await verifySessionToken(request.cookies.get(SESSION_COOKIE)?.value);
  const loginPath = request.nextUrl.pathname === '/login';
  if (loginPath && session) return NextResponse.redirect(new URL('/', request.url));
  if (!loginPath && !session) {
    const destination = new URL('/login', request.url);
    return NextResponse.redirect(destination);
  }
  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api/auth|_next/static|_next/image|favicon.ico).*)'],
};
