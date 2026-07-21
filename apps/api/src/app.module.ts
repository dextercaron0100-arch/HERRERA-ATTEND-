import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { PrismaService } from './prisma.service';
import { AttendanceController } from './attendance/attendance.controller';
import { AttendanceService } from './attendance/attendance.service';
import { WorkforceController } from './workforce/workforce.controller';
import { RequestsController } from './requests/requests.controller';
import { RequestsService } from './requests/requests.service';
import { PayrollController } from './payroll/payroll.controller';
import { PayrollService } from './payroll/payroll.service';
import { ReportsController } from './reports/reports.controller';
import { ReportsService } from './reports/reports.service';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { AuthGuard } from './auth/auth.guard';
import { PilotController } from './pilot/pilot.controller';
import { PilotService } from './pilot/pilot.service';
import { MobileController } from './mobile/mobile.controller';
import { CompensationController } from './compensation/compensation.controller';
import { CompensationService } from './compensation/compensation.service';
import { NotificationsController } from './notifications/notifications.controller';
import { NotificationsService } from './notifications/notifications.service';
@Module({ imports:[ThrottlerModule.forRoot([{ ttl:60000, limit:120 }])], controllers:[HealthController, AttendanceController, WorkforceController, RequestsController, PayrollController, ReportsController, PilotController, MobileController, CompensationController, NotificationsController], providers:[PrismaService, AttendanceService, RequestsService, PayrollService, ReportsService, PilotService, CompensationService, NotificationsService, {provide:APP_GUARD,useClass:AuthGuard}, {provide:APP_GUARD,useClass:ThrottlerGuard}] })
export class AppModule {}
