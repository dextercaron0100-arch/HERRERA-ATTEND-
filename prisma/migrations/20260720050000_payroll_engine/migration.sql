CREATE TYPE "PayrollPolicyStatus" AS ENUM ('DRAFT', 'APPROVED', 'RETIRED');
CREATE TYPE "PayrollLineCategory" AS ENUM ('EARNING', 'DEDUCTION', 'EMPLOYER_CONTRIBUTION');

ALTER TABLE "PayrollPolicy"
  ADD COLUMN "organizationId" TEXT NOT NULL,
  ADD COLUMN "status" "PayrollPolicyStatus" NOT NULL DEFAULT 'DRAFT',
  ADD COLUMN "createdById" TEXT NOT NULL,
  ADD COLUMN "approvedById" TEXT,
  ADD COLUMN "approvedAt" TIMESTAMP(3);
DROP INDEX "PayrollPolicy_name_version_key";
CREATE UNIQUE INDEX "PayrollPolicy_organizationId_name_version_key" ON "PayrollPolicy"("organizationId", "name", "version");
ALTER TABLE "PayrollPolicy" ADD CONSTRAINT "PayrollPolicy_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE "CompensationProfile" (
  "id" TEXT NOT NULL,
  "employeeId" TEXT NOT NULL,
  "effectiveFrom" DATE NOT NULL,
  "effectiveTo" DATE,
  "currency" TEXT NOT NULL DEFAULT 'PHP',
  "monthlyBase" DECIMAL(14,2) NOT NULL,
  "hourlyRate" DECIMAL(14,4),
  "allowances" JSONB NOT NULL,
  "deductions" JSONB NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "CompensationProfile_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "CompensationProfile_employeeId_effectiveFrom_key" ON "CompensationProfile"("employeeId", "effectiveFrom");
CREATE INDEX "CompensationProfile_employeeId_effectiveTo_idx" ON "CompensationProfile"("employeeId", "effectiveTo");
ALTER TABLE "CompensationProfile" ADD CONSTRAINT "CompensationProfile_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "Employee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "PayrollRun"
  ADD COLUMN "policyId" TEXT,
  ADD COLUMN "calculationHash" TEXT,
  ADD COLUMN "createdById" TEXT,
  ADD COLUMN "approvedById" TEXT,
  ADD COLUMN "reopenedAt" TIMESTAMP(3),
  ADD COLUMN "reopenReason" TEXT,
  ADD COLUMN "revision" INTEGER NOT NULL DEFAULT 1;
ALTER TABLE "PayrollRun" ADD CONSTRAINT "PayrollRun_policyId_fkey" FOREIGN KEY ("policyId") REFERENCES "PayrollPolicy"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "PayrollRun" ADD CONSTRAINT "PayrollRun_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "Employee"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "PayrollRun" ADD CONSTRAINT "PayrollRun_approvedById_fkey" FOREIGN KEY ("approvedById") REFERENCES "Employee"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "PayrollLineItem"
  ADD COLUMN "category" "PayrollLineCategory" NOT NULL DEFAULT 'EARNING',
  ADD COLUMN "taxable" BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE "PayrollAdjustment" (
  "id" TEXT NOT NULL,
  "payrollRunId" TEXT NOT NULL,
  "employeeId" TEXT NOT NULL,
  "createdById" TEXT NOT NULL,
  "code" TEXT NOT NULL,
  "description" TEXT NOT NULL,
  "amount" DECIMAL(14,2) NOT NULL,
  "reason" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PayrollAdjustment_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "PayrollAdjustment_payrollRunId_employeeId_idx" ON "PayrollAdjustment"("payrollRunId", "employeeId");
ALTER TABLE "PayrollAdjustment" ADD CONSTRAINT "PayrollAdjustment_payrollRunId_fkey" FOREIGN KEY ("payrollRunId") REFERENCES "PayrollRun"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "PayrollAdjustment" ADD CONSTRAINT "PayrollAdjustment_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "Employee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE "PayrollRunHistory" (
  "id" TEXT NOT NULL,
  "payrollRunId" TEXT NOT NULL,
  "actorId" TEXT NOT NULL,
  "action" TEXT NOT NULL,
  "fromStatus" "PayrollStatus" NOT NULL,
  "toStatus" "PayrollStatus" NOT NULL,
  "reason" TEXT,
  "revision" INTEGER NOT NULL,
  "occurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PayrollRunHistory_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "PayrollRunHistory_payrollRunId_occurredAt_idx" ON "PayrollRunHistory"("payrollRunId", "occurredAt");
ALTER TABLE "PayrollRunHistory" ADD CONSTRAINT "PayrollRunHistory_payrollRunId_fkey" FOREIGN KEY ("payrollRunId") REFERENCES "PayrollRun"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE "Payslip" (
  "id" TEXT NOT NULL,
  "payrollRunId" TEXT NOT NULL,
  "employeeId" TEXT NOT NULL,
  "storageKey" TEXT NOT NULL,
  "contentHash" TEXT NOT NULL,
  "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Payslip_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Payslip_payrollRunId_employeeId_key" ON "Payslip"("payrollRunId", "employeeId");
ALTER TABLE "Payslip" ADD CONSTRAINT "Payslip_payrollRunId_fkey" FOREIGN KEY ("payrollRunId") REFERENCES "PayrollRun"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
