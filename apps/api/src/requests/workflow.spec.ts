import { defaultApprovalRoles, nextRequestState } from './workflow';
describe('request workflow',()=>{
  it('advances maker-checker approval',()=>expect(nextRequestState('APPROVED',1,2)).toEqual({status:'PENDING',currentStep:2,complete:false}));
  it('completes the final approval',()=>expect(nextRequestState('APPROVED',2,2).status).toBe('APPROVED'));
  it('rejects immediately',()=>expect(nextRequestState('REJECTED',1,2).status).toBe('REJECTED'));
  it('requires supervisor and HR for corrections',()=>expect(defaultApprovalRoles('ATTENDANCE_CORRECTION')).toEqual(['SUPERVISOR','HR']));
});
