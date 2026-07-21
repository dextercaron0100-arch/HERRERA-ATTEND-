CREATE TABLE "RegisteredDevice" (
  "id" TEXT NOT NULL,
  "employeeId" TEXT NOT NULL,
  "deviceId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "platform" TEXT NOT NULL,
  "biometricsEnabled" BOOLEAN NOT NULL DEFAULT false,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "registeredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "RegisteredDevice_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "RegisteredDevice_deviceId_key" ON "RegisteredDevice"("deviceId");
CREATE INDEX "RegisteredDevice_employeeId_active_idx" ON "RegisteredDevice"("employeeId", "active");
ALTER TABLE "RegisteredDevice" ADD CONSTRAINT "RegisteredDevice_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "Employee"("id") ON DELETE CASCADE ON UPDATE CASCADE;
