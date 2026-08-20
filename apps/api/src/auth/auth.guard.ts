import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { createRemoteJWKSet, jwtVerify, type JWTPayload } from 'jose';
import { PrismaService } from '../prisma.service';
import { IS_PUBLIC_KEY } from './public.decorator';

export type GeoAttendIdentity = {
  subject: string;
  employeeId: string;
  organizationId: string;
  role: string;
};

type RequestShape = {
  headers: Record<string, string | string[] | undefined>;
  body?: Record<string, unknown>;
  query?: Record<string, unknown>;
  user?: GeoAttendIdentity;
};

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly supabaseUrl = process.env.SUPABASE_URL?.replace(/\/$/u, '');
  private readonly jwks = this.supabaseUrl
    ? createRemoteJWKSet(new URL(`${this.supabaseUrl}/auth/v1/.well-known/jwks.json`))
    : undefined;

  constructor(
    private readonly reflector: Reflector,
    private readonly db: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [context.getHandler(), context.getClass()])) {
      return true;
    }

    const request = context.switchToHttp().getRequest<RequestShape>();
    const authorization = request.headers.authorization;
    const header = Array.isArray(authorization) ? authorization[0] : authorization;
    if (!header?.startsWith('Bearer ')) throw new UnauthorizedException('Bearer token required');
    if (!this.jwks || !this.supabaseUrl) {
      throw new UnauthorizedException('Supabase JWT verification is not configured');
    }

    let payload: JWTPayload;
    try {
      ({ payload } = await jwtVerify(header.slice(7), this.jwks, {
        issuer: `${this.supabaseUrl}/auth/v1`,
        audience: 'authenticated',
      }));
    } catch {
      throw new UnauthorizedException('Invalid or expired Supabase token');
    }

    if (!payload.sub) throw new UnauthorizedException('Supabase token subject is missing');
    const identity = await this.resolveEmployeeIdentity(payload);
    this.assertTenantConsistency(request, identity);
    request.user = identity;
    return true;
  }

  private async resolveEmployeeIdentity(payload: JWTPayload): Promise<GeoAttendIdentity> {
    const subject = payload.sub!;
    const linked = await this.db.employee.findUnique({
      where: { authUserId: subject },
      select: { id: true, authUserId: true, organizationId: true, role: true, active: true },
    });
    if (linked) {
      if (!linked.active) throw new UnauthorizedException('This employee account is suspended');
      return this.identity(subject, linked);
    }

    const email = this.stringClaim(payload, 'email')?.trim().toLowerCase();
    if (!email) {
      throw new UnauthorizedException('This Supabase account is not linked to a Herrera employee');
    }

    const matches = await this.db.employee.findMany({
      where: { active: true, email: { equals: email, mode: 'insensitive' } },
      select: { id: true, authUserId: true, organizationId: true, role: true, active: true },
    });
    if (matches.length === 0) {
      throw new UnauthorizedException('No active Herrera employee uses this email address');
    }
    if (matches.length > 1) {
      throw new UnauthorizedException('Multiple active employee records use this email address');
    }

    const employee = matches[0];
    if (employee.authUserId && employee.authUserId !== subject) {
      throw new UnauthorizedException('This employee is already linked to another Supabase account');
    }
    if (!employee.authUserId) {
      const linkedNow = await this.db.employee.updateMany({
        where: { id: employee.id, authUserId: null },
        data: { authUserId: subject },
      });
      if (linkedNow.count === 0) {
        const current = await this.db.employee.findUnique({
          where: { id: employee.id },
          select: { authUserId: true },
        });
        if (current?.authUserId !== subject) {
          throw new UnauthorizedException('This employee was linked to another Supabase account');
        }
      }
    }

    return this.identity(subject, employee);
  }

  private identity(
    subject: string,
    employee: { id: string; organizationId: string; role: string },
  ): GeoAttendIdentity {
    return {
      subject,
      employeeId: employee.id,
      organizationId: employee.organizationId,
      role: employee.role,
    };
  }

  private stringClaim(payload: JWTPayload, name: string) {
    const value = payload[name];
    return typeof value === 'string' && value.length > 0 ? value : undefined;
  }

  private assertTenantConsistency(request: RequestShape, identity: GeoAttendIdentity) {
    const supplied = { ...request.query, ...request.body };
    if (supplied.organizationId && supplied.organizationId !== identity.organizationId) {
      throw new ForbiddenException('Cross-organization access denied');
    }
    if (supplied.actorId && supplied.actorId !== identity.employeeId) {
      throw new ForbiddenException('Actor identity does not match token');
    }
    if (identity.role === 'EMPLOYEE' && supplied.employeeId && supplied.employeeId !== identity.employeeId) {
      throw new ForbiddenException('Employees may only access their own records');
    }
  }
}
