import { PrismaClient } from '@prisma/client';
const db=new PrismaClient();
async function main(){
  const organization=await db.organization.create({data:{name:'Herrera Demo Company'}});
  const worksite=await db.worksite.create({data:{organizationId:organization.id,name:'Main Office',latitude:14.5995,longitude:120.9842,radiusMeters:100,maxAccuracyMeters:50}});
  const department=await db.department.create({data:{organizationId:organization.id,name:'Operations'}});
  const schedule=await db.schedule.create({data:{organizationId:organization.id,name:'Weekday 08:00-17:00',shifts:{create:[1,2,3,4,5].map(dayOfWeek=>({dayOfWeek,startMinute:480,endMinute:1020,breakMinutes:60,graceMinutes:10}))}}});
  const employee=await db.employee.create({data:{organizationId:organization.id,employeeNumber:'EMP-001',name:'Maria Santos',email:'maria@example.test',worksiteId:worksite.id,departmentId:department.id,scheduleId:schedule.id}});
  await db.employee.createMany({data:[{organizationId:organization.id,employeeNumber:'SUP-001',name:'Jose Supervisor',email:'supervisor@example.test',role:'SUPERVISOR',departmentId:department.id},{organizationId:organization.id,employeeNumber:'HR-001',name:'Ana HR',email:'hr@example.test',role:'HR',departmentId:department.id},{organizationId:organization.id,employeeNumber:'ADMIN-001',name:'Herrera Super Admin',email:'admin@example.test',role:'ADMIN',departmentId:department.id}]});
  const payrollUser=await db.employee.create({data:{organizationId:organization.id,employeeNumber:'PAY-001',name:'Paolo Payroll',email:'payroll@example.test',role:'PAYROLL',departmentId:department.id}});
  const financeUser=await db.employee.create({data:{organizationId:organization.id,employeeNumber:'FIN-001',name:'Liza Finance',email:'finance@example.test',role:'FINANCE',departmentId:department.id}});
  await db.approvalPolicy.createMany({data:[{organizationId:organization.id,requestType:'LEAVE',name:'Standard leave',steps:['SUPERVISOR','HR']},{organizationId:organization.id,requestType:'OVERTIME',name:'Standard overtime',steps:['SUPERVISOR','HR']},{organizationId:organization.id,requestType:'ATTENDANCE_CORRECTION',name:'Attendance correction',steps:['SUPERVISOR','HR']}]});
  await db.compensationProfile.create({data:{employeeId:employee.id,effectiveFrom:new Date('2026-07-01'),currency:'PHP',monthlyBase:'20000.00',hourlyRate:'100.0000',allowances:[{code:'DEMO_MEAL',description:'Demo meal allowance',amount:'500.00',taxable:false}],deductions:[]}});
  await db.payrollPolicy.create({data:{organizationId:organization.id,name:'Demo pilot policy',version:1,status:'APPROVED',effectiveFrom:new Date('2026-07-01'),currency:'PHP',createdById:payrollUser.id,approvedById:financeUser.id,approvedAt:new Date(),rules:{classification:'DEMO_ONLY_NOT_STATUTORY',basePayDivisor:2,regularMinutesPerDay:480,overtimeMultiplier:'1.25',rounding:'HALF_UP',deductions:[]}}});
  console.log({organizationId:organization.id,worksiteId:worksite.id,employeeId:employee.id,scheduleId:schedule.id,payrollUserId:payrollUser.id,financeUserId:financeUser.id});
}
main().finally(()=>db.$disconnect());
