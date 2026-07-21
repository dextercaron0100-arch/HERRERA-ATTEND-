import Decimal from 'decimal.js';

export type ReferenceInput = { employeeId: string; code: string; trustedAmount: string; explanation?: string };
export type SystemLine = { employeeId: string; code: string; amount: string | number | Decimal };

export function reconcileLines(reference: ReferenceInput[], system: SystemLine[], tolerance: string | number) {
  const allowed = new Decimal(tolerance);
  return reference.map(line => {
    const systemAmount = system
      .filter(item => item.employeeId === line.employeeId && item.code === line.code)
      .reduce((total, item) => total.plus(item.amount), new Decimal(0));
    const trustedAmount = new Decimal(line.trustedAmount);
    const variance = systemAmount.minus(trustedAmount);
    return {
      ...line,
      trustedAmount: trustedAmount.toFixed(2),
      systemAmount: systemAmount.toFixed(2),
      variance: variance.toFixed(2),
      resolved: variance.abs().lte(allowed),
    };
  });
}
