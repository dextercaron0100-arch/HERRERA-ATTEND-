CREATE TYPE "ReportType" AS ENUM ('DAILY_ATTENDANCE', 'TIMECARD', 'EXCEPTIONS', 'OVERTIME', 'PAYROLL_REGISTER', 'PAYROLL_SUMMARY', 'PAYROLL_VARIANCE', 'DEDUCTIONS', 'AUDIT_LOG');
CREATE TYPE "ExportFormat" AS ENUM ('CSV', 'PDF');

CREATE TABLE "ReportExport" (
  "id" TEXT NOT NULL,
  "organizationId" TEXT NOT NULL,
  "requestedById" TEXT NOT NULL,
  "reportType" "ReportType" NOT NULL,
  "format" "ExportFormat" NOT NULL,
  "filters" JSONB NOT NULL,
  "rowCount" INTEGER NOT NULL,
  "contentHash" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ReportExport_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "ReportExport_organizationId_createdAt_idx" ON "ReportExport"("organizationId", "createdAt");
CREATE INDEX "ReportExport_requestedById_createdAt_idx" ON "ReportExport"("requestedById", "createdAt");
ALTER TABLE "ReportExport" ADD CONSTRAINT "ReportExport_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
