import { reconcileLines } from './reconciliation';

describe('pilot reconciliation', () => {
  it('aggregates system lines and reports signed decimal variance', () => {
    const result = reconcileLines(
      [{ employeeId: 'e1', code: 'NET_PAY', trustedAmount: '1000.00' }],
      [{ employeeId: 'e1', code: 'NET_PAY', amount: '600.10' }, { employeeId: 'e1', code: 'NET_PAY', amount: '399.85' }],
      '0.10',
    );
    expect(result[0]).toMatchObject({ systemAmount: '999.95', variance: '-0.05', resolved: true });
  });

  it('keeps out-of-tolerance and missing reference lines unresolved', () => {
    const result = reconcileLines([{ employeeId: 'e1', code: 'TAX', trustedAmount: '50' }], [], '0.01');
    expect(result[0]).toMatchObject({ systemAmount: '0.00', variance: '-50.00', resolved: false });
  });
});
