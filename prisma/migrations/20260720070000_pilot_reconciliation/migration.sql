CREATE TYPE "PilotStatus" AS ENUM ('PLANNED', 'ACTIVE', 'COMPLETED', 'HALTED');
CREATE TYPE "PilotCycleStatus" AS ENUM ('OPEN', 'RECONCILED', 'SIGNED_OFF');

CREATE TABLE "Pilot" (
  "id" TEXT NOT NULL,
  "organizationId" TEXT NOT NULL,
  "worksiteId" TEXT,
  "name" TEXT NOT NULL,
  "status" "PilotStatus" NOT NULL DEFAULT 'PLANNED',
  "tolerance" DECIMAL(14,2) NOT NULL DEFAULT 0,
  "targetCycles" INTEGER NOT NULL DEFAULT 2,
  "startsAt" TIMESTAMP(3) NOT NULL,
  "endsAt" TIMESTAMP(3),
  "createdById" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Pilot_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "PilotMember" (
  "id" TEXT NOT NULL,
  "pilotId" TEXT NOT NULL,
  "employeeId" TEXT NOT NULL,
  "enrolledAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PilotMember_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "PilotCycle" (
  "id" TEXT NOT NULL,
  "pilotId" TEXT NOT NULL,
  "payrollRunId" TEXT NOT NULL,
  "cycleNumber" INTEGER NOT NULL,
  "status" "PilotCycleStatus" NOT NULL DEFAULT 'OPEN',
  "reconciledAt" TIMESTAMP(3),
  "signedOffAt" TIMESTAMP(3),
  "signedOffById" TEXT,
  "notes" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PilotCycle_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "PilotReferenceLine" (
  "id" TEXT NOT NULL,
  "pilotCycleId" TEXT NOT NULL,
  "employeeId" TEXT NOT NULL,
  "code" TEXT NOT NULL,
  "trustedAmount" DECIMAL(14,2) NOT NULL,
  "systemAmount" DECIMAL(14,2) NOT NULL,
  "variance" DECIMAL(14,2) NOT NULL,
  "explanation" TEXT,
  "resolved" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PilotReferenceLine_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Pilot_organizationId_status_idx" ON "Pilot"("organizationId", "status");
CREATE UNIQUE INDEX "PilotMember_pilotId_employeeId_key" ON "PilotMember"("pilotId", "employeeId");
CREATE UNIQUE INDEX "PilotCycle_payrollRunId_key" ON "PilotCycle"("payrollRunId");
CREATE UNIQUE INDEX "PilotCycle_pilotId_cycleNumber_key" ON "PilotCycle"("pilotId", "cycleNumber");
CREATE UNIQUE INDEX "PilotReferenceLine_pilotCycleId_employeeId_code_key" ON "PilotReferenceLine"("pilotCycleId", "employeeId", "code");
CREATE INDEX "PilotReferenceLine_pilotCycleId_resolved_idx" ON "PilotReferenceLine"("pilotCycleId", "resolved");
ALTER TABLE "Pilot" ADD CONSTRAINT "Pilot_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "PilotMember" ADD CONSTRAINT "PilotMember_pilotId_fkey" FOREIGN KEY ("pilotId") REFERENCES "Pilot"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PilotMember" ADD CONSTRAINT "PilotMember_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "Employee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "PilotCycle" ADD CONSTRAINT "PilotCycle_pilotId_fkey" FOREIGN KEY ("pilotId") REFERENCES "Pilot"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PilotCycle" ADD CONSTRAINT "PilotCycle_payrollRunId_fkey" FOREIGN KEY ("payrollRunId") REFERENCES "PayrollRun"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "PilotReferenceLine" ADD CONSTRAINT "PilotReferenceLine_pilotCycleId_fkey" FOREIGN KEY ("pilotCycleId") REFERENCES "PilotCycle"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PilotReferenceLine" ADD CONSTRAINT "PilotReferenceLine_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "Employee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
