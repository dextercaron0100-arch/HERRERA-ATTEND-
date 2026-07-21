import { CanActivate, ExecutionContext, Injectable, UnauthorizedException, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { createRemoteJWKSet, jwtVerify, JWTPayload } from 'jose';
import { IS_PUBLIC_KEY } from './public.decorator';

export type GeoAttendIdentity = {
  subject: string;
  employeeId?: string;
  organizationId?: string;
  role?: string;
};

type RequestShape = {
  headers: Record<string, string | string[] | undefined>;
  body?: Record<string, unknown>;
  query?: Record<string, unknown>;
  user?: GeoAttendIdentity;
};

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly mode = process.env.AUTH_MODE ?? 'development';
  private readonly jwks = process.env.JWT_JWKS_URL
    ? createRemoteJWKSet(new URL(process.env.JWT_JWKS_URL))
    : undefined;

  constructor(private readonly reflector: Reflector) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [context.getHandler(), context.getClass()])) return true;

    const request = context.switchToHttp().getRequest<RequestShape>();
    if (this.mode === 'development') {
      request.user = { subject: 'local-development', role: 'ADMIN' };
      return true;
    }

    const authorization = request.headers.authorization;
    const header = Array.isArray(authorization) ? authorization[0] : authorization;
    if (!header?.startsWith('Bearer ')) throw new UnauthorizedException('Bearer token required');
    if (!this.jwks || !process.env.JWT_ISSUER) {
      throw new UnauthorizedException('JWT verification is not configured');
    }

    let payload: JWTPayload;
    try {
      ({ payload } = await jwtVerify(header.slice(7), this.jwks, {
        issuer: process.env.JWT_ISSUER,
        ...(process.env.JWT_AUDIENCE ? { audience: process.env.JWT_AUDIENCE } : {}),
      }));
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }

    const identity: GeoAttendIdentity = {
      subject: payload.sub ?? '',
      employeeId: this.claim(payload, 'employee_id') ?? this.nestedClaim(payload, 'public_metadata', 'employeeId'),
      organizationId: this.claim(payload, 'organization_id') ?? this.claim(payload, 'org_id') ?? this.nestedClaim(payload, 'o', 'id'),
      role: this.claim(payload, 'role') ?? this.claim(payload, 'org_role') ?? this.nestedClaim(payload, 'o', 'rol'),
    };
    if (!identity.subject || !identity.organizationId) throw new UnauthorizedException('Required identity claims are missing');
    this.assertTenantConsistency(request, identity);
    request.user = identity;
    return true;
  }

  private claim(payload: JWTPayload, name: string): string | undefined {
    const value = payload[name];
    return typeof value === 'string' && value.length > 0 ? value : undefined;
  }

  private nestedClaim(payload: JWTPayload, parent: string, name: string): string | undefined {
    const container = payload[parent];
    if (!container || typeof container !== 'object' || Array.isArray(container)) return undefined;
    const value = (container as Record<string, unknown>)[name];
    return typeof value === 'string' && value.length > 0 ? value : undefined;
  }

  private assertTenantConsistency(request: RequestShape, identity: GeoAttendIdentity) {
    const supplied = { ...request.query, ...request.body };
    if (supplied.organizationId && supplied.organizationId !== identity.organizationId) {
      throw new ForbiddenException('Cross-organization access denied');
    }
    if (supplied.actorId && (!identity.employeeId || supplied.actorId !== identity.employeeId)) {
      throw new ForbiddenException('Actor identity does not match token');
    }
    if (identity.role === 'EMPLOYEE' && supplied.employeeId && supplied.employeeId !== identity.employeeId) {
      throw new ForbiddenException('Employees may only access their own records');
    }
  }
}
