import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse, type NextRequest } from 'next/server';
import { isClerkConfigured } from './app/lib/auth-mode';
import { SESSION_COOKIE, verifySessionToken } from './app/lib/session';

const isPublicRoute = createRouteMatcher(['/login(.*)', '/api/auth/(login|logout)']);

async function devAuthMiddleware(request: NextRequest) {
  if (isPublicRoute(request)) return NextResponse.next();
  const session = await verifySessionToken(request.cookies.get(SESSION_COOKIE)?.value);
  if (!session) return NextResponse.redirect(new URL('/login', request.url));
  return NextResponse.next();
}

export default isClerkConfigured
  ? clerkMiddleware(async (auth, request) => {
      if (!isPublicRoute(request)) await auth.protect();
    }, { frontendApiProxy: { enabled: true } })
  : devAuthMiddleware;

export const config = {
  matcher: [
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    '/__clerk(.*)',
    '/(api|trpc)(.*)',
  ],
};
