import { summarizeEvents } from './summary';
const event=(id:string,kind:any,time:string)=>({id,kind,capturedAt:new Date(time)});
describe('attendance summary',()=>{
  it('calculates worked time excluding breaks',()=>{const result=summarizeEvents([event('1','CLOCK_IN','2026-07-20T00:00:00Z'),event('2','BREAK_START','2026-07-20T04:00:00Z'),event('3','BREAK_END','2026-07-20T05:00:00Z'),event('4','CLOCK_OUT','2026-07-20T09:00:00Z')]);expect(result.workedMinutes).toBe(480);expect(result.breakMinutes).toBe(60);expect(result.missingPunch).toBe(false);});
  it('flags an unmatched clock in',()=>expect(summarizeEvents([event('1','CLOCK_IN','2026-07-20T00:00:00Z')]).missingPunch).toBe(true));
});
