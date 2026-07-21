import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { Public } from './auth/public.decorator';

@Public()
@Controller('health')
export class HealthController {
  constructor(private readonly db: PrismaService) {}

  @Get('live')
  live() { return { status: 'ok', service: 'geoattend-api', timestamp: new Date().toISOString() }; }

  @Get()
  async ready() {
    try {
      await this.db.$queryRaw`SELECT 1`;
      return { status: 'ready', service: 'geoattend-api', dependencies: { postgres: 'ok' }, timestamp: new Date().toISOString() };
    } catch {
      throw new ServiceUnavailableException({ status: 'not-ready', dependencies: { postgres: 'unavailable' } });
    }
  }
}
