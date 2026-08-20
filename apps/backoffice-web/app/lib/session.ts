export type BackofficeSession = {
  employeeId: string;
  organizationId: string;
  employeeNumber: string;
  name: string;
  email: string;
  role: string;
  passwordResetRequired: boolean;
  expiresAt: number;
};
