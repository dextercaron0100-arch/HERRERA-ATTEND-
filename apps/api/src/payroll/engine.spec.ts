import { calculateEmployee } from './engine';
const rules={basePayDivisor:2,regularMinutesPerDay:480,overtimeMultiplier:'1.25',deductions:[{code:'DEMO_STAT',description:'Approved demo contribution',type:'FIXED' as const,value:100}]};
describe('payroll engine',()=>{
  it('calculates explainable decimal line items exactly',()=>{const result=calculateEmployee({employeeId:'e1',monthlyBase:'20000.00',hourlyRate:'100.00',workedMinutes:4800,scheduledMinutes:4800,overtimeMinutes:120,lateMinutes:10,undertimeMinutes:20,allowances:[{code:'MEAL',description:'Meal allowance',amount:'500',taxable:false}]},rules);expect(result.totals).toEqual({gross:'10750.00',deductions:'150.00',taxableIncome:'10250.00',net:'10600.00'});expect(result.lines.find(l=>l.code==='OVERTIME')?.amount).toBe('250.00');});
  it('does not use floating point arithmetic for money',()=>{const result=calculateEmployee({employeeId:'e1',monthlyBase:'0.30',hourlyRate:'0.10',workedMinutes:1,scheduledMinutes:1,overtimeMinutes:1,lateMinutes:0,undertimeMinutes:0},rules);expect(result.lines[0].amount).toBe('0.15');});
  it('rejects an invalid unapproved rule shape',()=>expect(()=>calculateEmployee({employeeId:'e',monthlyBase:1,workedMinutes:0,scheduledMinutes:0,overtimeMinutes:0,lateMinutes:0,undertimeMinutes:0},{...rules,basePayDivisor:0})).toThrow());
});
