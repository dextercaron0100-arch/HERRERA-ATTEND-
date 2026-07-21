export type WorkflowDecision='APPROVED'|'REJECTED';
export function nextRequestState(decision:WorkflowDecision,currentStep:number,totalSteps:number){
  if(decision==='REJECTED') return {status:'REJECTED' as const,currentStep,complete:true};
  if(currentStep>=totalSteps) return {status:'APPROVED' as const,currentStep,complete:true};
  return {status:'PENDING' as const,currentStep:currentStep+1,complete:false};
}
export function defaultApprovalRoles(type:string):string[]{
  if(type==='OVERTIME'||type==='ATTENDANCE_CORRECTION') return ['SUPERVISOR','HR'];
  if(type==='LEAVE') return ['SUPERVISOR','HR'];
  return ['SUPERVISOR'];
}
