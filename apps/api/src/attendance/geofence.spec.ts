import { decideAttendance, distanceMeters } from './geofence';
describe('geofence',()=>{
  it('calculates a zero distance',()=>expect(distanceMeters(14.5995,120.9842,14.5995,120.9842)).toBe(0));
  it('accepts accurate evidence inside radius',()=>expect(decideAttendance(10,100,8,50).decision).toBe('ACCEPTED'));
  it('rejects accurate evidence outside radius',()=>expect(decideAttendance(120,100,8,50).decision).toBe('REJECTED'));
  it('reviews low accuracy instead of falsely rejecting',()=>expect(decideAttendance(120,100,80,50).decision).toBe('REVIEW'));
});
