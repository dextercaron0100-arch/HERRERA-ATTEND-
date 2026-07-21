import Decimal from 'decimal.js';
Decimal.set({precision:28,rounding:Decimal.ROUND_HALF_UP});
export type MoneyInput=string|number;
export interface Component {code:string;description:string;amount:MoneyInput;taxable?:boolean}
export interface DeductionRule {code:string;description:string;type:'FIXED'|'GROSS_RATE';value:MoneyInput}
export interface PayrollRules {basePayDivisor:MoneyInput;regularMinutesPerDay:number;overtimeMultiplier:MoneyInput;deductions?:DeductionRule[]}
export interface PayrollEmployeeInput {employeeId:string;monthlyBase:MoneyInput;hourlyRate?:MoneyInput|null;workedMinutes:number;scheduledMinutes:number;overtimeMinutes:number;lateMinutes:number;undertimeMinutes:number;allowances?:Component[];deductions?:Component[]}
export interface CalculatedLine {code:string;description:string;category:'EARNING'|'DEDUCTION';amount:string;taxable:boolean;explanation:Record<string,unknown>}
const money=(value:Decimal.Value)=>new Decimal(value).toDecimalPlaces(2).toFixed(2);
export function calculateEmployee(input:PayrollEmployeeInput,rules:PayrollRules){
  if(new Decimal(rules.basePayDivisor).lte(0)||rules.regularMinutesPerDay<=0)throw new Error('Invalid approved payroll policy');
  const basePay=new Decimal(input.monthlyBase).div(rules.basePayDivisor);
  const hourly=input.hourlyRate!=null?new Decimal(input.hourlyRate):basePay.div(input.scheduledMinutes||rules.regularMinutesPerDay).mul(60);
  const minuteRate=hourly.div(60); const lines:CalculatedLine[]=[];
  lines.push({code:'BASIC_PAY',description:'Basic pay',category:'EARNING',amount:money(basePay),taxable:true,explanation:{monthlyBase:String(input.monthlyBase),divisor:String(rules.basePayDivisor)}});
  if(input.overtimeMinutes>0){const amount=minuteRate.mul(input.overtimeMinutes).mul(rules.overtimeMultiplier);lines.push({code:'OVERTIME',description:'Approved overtime',category:'EARNING',amount:money(amount),taxable:true,explanation:{minutes:input.overtimeMinutes,multiplier:String(rules.overtimeMultiplier),hourlyRate:hourly.toString()}});}
  for(const item of input.allowances??[])lines.push({code:item.code,description:item.description,category:'EARNING',amount:money(item.amount),taxable:item.taxable??true,explanation:{source:'COMPENSATION_PROFILE'}});
  const attendanceMinutes=input.lateMinutes+input.undertimeMinutes;
  if(attendanceMinutes>0){lines.push({code:'TIME_DEDUCTION',description:'Late and undertime',category:'DEDUCTION',amount:money(minuteRate.mul(attendanceMinutes)),taxable:false,explanation:{lateMinutes:input.lateMinutes,undertimeMinutes:input.undertimeMinutes,hourlyRate:hourly.toString()}});}
  for(const item of input.deductions??[])lines.push({code:item.code,description:item.description,category:'DEDUCTION',amount:money(item.amount),taxable:false,explanation:{source:'COMPENSATION_PROFILE'}});
  const gross=lines.filter(l=>l.category==='EARNING').reduce((sum,l)=>sum.plus(l.amount),new Decimal(0));
  for(const rule of rules.deductions??[]){const amount=rule.type==='FIXED'?new Decimal(rule.value):gross.mul(rule.value);lines.push({code:rule.code,description:rule.description,category:'DEDUCTION',amount:money(amount),taxable:false,explanation:{source:'APPROVED_POLICY',type:rule.type,value:String(rule.value)}});}
  const deductions=lines.filter(l=>l.category==='DEDUCTION').reduce((sum,l)=>sum.plus(l.amount),new Decimal(0));
  const taxableIncome=lines.filter(l=>l.category==='EARNING'&&l.taxable).reduce((sum,l)=>sum.plus(l.amount),new Decimal(0));
  return {employeeId:input.employeeId,lines,totals:{gross:money(gross),deductions:money(deductions),taxableIncome:money(taxableIncome),net:money(gross.minus(deductions))}};
}
