ALTER TABLE "Employee" ADD COLUMN "authUserId" TEXT;

CREATE UNIQUE INDEX "Employee_authUserId_key" ON "Employee"("authUserId");
