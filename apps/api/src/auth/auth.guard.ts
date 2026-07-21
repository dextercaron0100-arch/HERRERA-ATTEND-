import { CanActivate, ExecutionContext, Injectable, UnauthorizedException, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { createRemoteJWKSet, jwtVerify, JWTPayload } from 'jose';
import { PrismaService } from '../prisma.service';
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

type CachedIdentity = {
  identity: GeoAttendIdentity;
  expiresAt: number;
};

const BUSINESS_ROLES = new Set(['EMPLOYEE', 'SUPERVISOR', 'HR', 'PAYROLL', 'FINANCE', 'ADMIN', 'AUDITOR']);
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/iu;

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly mode = process.env.AUTH_MODE ?? 'development';
  private readonly jwks = process.env.JWT_JWKS_URL
    ? createRemoteJWKSet(new URL(process.env.JWT_JWKS_URL))
    : undefined;
  private readonly identityCache = new Map<string, CachedIdentity>();

  constructor(
    private readonly reflector: Reflector,
    private readonly db: PrismaService,
  ) {}

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

    let identity: GeoAttendIdentity = {
      subject: payload.sub ?? '',
      employeeId: this.claim(payload, 'employee_id') ?? this.nestedClaim(payload, 'public_metadata', 'employeeId'),
      organizationId: this.claim(payload, 'organization_id') ?? this.claim(payload, 'org_id')
        ?? this.nestedClaim(payload, 'public_metadata', 'organizationId') ?? this.nestedClaim(payload, 'o', 'id'),
      role: this.normalizeRole(
        this.claim(payload, 'role') ?? this.claim(payload, 'org_role')
          ?? this.nestedClaim(payload, 'public_metadata', 'accessLevel')
          ?? this.nestedClaim(payload, 'public_metadata', 'role')
          ?? this.nestedClaim(payload, 'o', 'rol'),
      ),
    };

    if (!identity.subject) throw new UnauthorizedException('Required identity claims are missing');
    if (this.requiresEmployeeResolution(identity)) {
      identity = await this.resolveEmployeeIdentity(payload, identity);
    }
    if (!identity.employeeId || !identity.organizationId || !identity.role) {
      throw new UnauthorizedException('This account is not linked to an active Herrera employee');
    }

    this.assertTenantConsistency(request, identity);
    request.user = identity;
    return true;
  }

  private requiresEmployeeResolution(identity: GeoAttendIdentity) {
    return !identity.employeeId || !UUID_PATTERN.test(identity.employeeId)
      || !identity.organizationId || !UUID_PATTERN.test(identity.organizationId)
      || !identity.role || !BUSINESS_ROLES.has(identity.role);
  }

  private async resolveEmployeeIdentity(payload: JWTPayload, identity: GeoAttendIdentity): Promise<GeoAttendIdentity> {
    const cached = this.identityCache.get(identity.subject);
    if (cached && cached.expiresAt > Date.now()) return cached.identity;

    const email = this.claim(payload, 'email')
      ?? this.claim(payload, 'primary_email')
      ?? this.nestedClaim(payload, 'public_metadata', 'email');
    if (!email) throw new UnauthorizedException('The identity token does not include an email address');

    const matches = await this.db.employee.findMany({
      where: { active: true, email: { equals: email.trim(), mode: 'insensitive' } },
      select: { id: true, organizationId: true, role: true },
      take: 2,
    });
    if (matches.length === 0) {
      throw new UnauthorizedException('No active Herrera employee uses this email address');
    }
    if (matches.length > 1) {
      throw new UnauthorizedException('Multiple active employee records use this email address');
    }

    const employee = matches[0];
    const resolved: GeoAttendIdentity = {
      subject: identity.subject,
      employeeId: employee.id,
      organizationId: employee.organizationId,
      role: employee.role,
    };
    this.identityCache.set(identity.subject, { identity: resolved, expiresAt: Date.now() + 5 * 60 * 1000 });
    return resolved;
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

  private normalizeRole(value: string | undefined): string | undefined {
    const normalized = value?.replace(/^org:/u, '').replaceAll('-', '_').replaceAll(' ', '_').toUpperCase();
    if (normalized === 'SUPER_ADMIN') return 'ADMIN';
    return normalized && BUSINESS_ROLES.has(normalized) ? normalized : undefined;
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
