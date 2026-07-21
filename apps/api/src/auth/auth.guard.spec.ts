import { ExecutionContext, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from './auth.guard';

const context = (request: Record<string, unknown>) => ({
  getHandler: () => function handler() {},
  getClass: () => class Controller {},
  switchToHttp: () => ({ getRequest: () => request }),
}) as unknown as ExecutionContext;

describe('AuthGuard', () => {
  const prior = process.env.AUTH_MODE;
  afterEach(() => { process.env.AUTH_MODE = prior; });

  it('allows local development requests', async () => {
    process.env.AUTH_MODE = 'development';
    const request = { headers: {} };
    await expect(new AuthGuard(new Reflector()).canActivate(context(request))).resolves.toBe(true);
    expect(request).toHaveProperty('user.role', 'ADMIN');
  });

  it('rejects missing production bearer tokens', async () => {
    process.env.AUTH_MODE = 'production';
    await expect(new AuthGuard(new Reflector()).canActivate(context({ headers: {} }))).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('rejects cross-tenant values before controllers are called', () => {
    const guard = new AuthGuard(new Reflector()) as unknown as { assertTenantConsistency(request: unknown, identity: unknown): void };
    expect(() => guard.assertTenantConsistency(
      { headers: {}, query: { organizationId: 'other-org' } },
      { subject: 'user', organizationId: 'org-1', employeeId: 'employee-1' },
    )).toThrow(ForbiddenException);
  });
});
