export interface SummaryEvent { id:string; kind:'CLOCK_IN'|'BREAK_START'|'BREAK_END'|'CLOCK_OUT'; capturedAt:Date }
export function summarizeEvents(events:SummaryEvent[]){
  const ordered=[...events].sort((a,b)=>a.capturedAt.getTime()-b.capturedAt.getTime());
  let activeStart:Date|undefined, breakStart:Date|undefined, worked=0, breaks=0;
  for(const event of ordered){
    if(event.kind==='CLOCK_IN'&&!activeStart) activeStart=event.capturedAt;
    if(event.kind==='BREAK_START'&&activeStart&&!breakStart) breakStart=event.capturedAt;
    if(event.kind==='BREAK_END'&&breakStart){breaks+=Math.max(0,Math.round((event.capturedAt.getTime()-breakStart.getTime())/60000));breakStart=undefined;}
    if(event.kind==='CLOCK_OUT'&&activeStart){worked+=Math.max(0,Math.round((event.capturedAt.getTime()-activeStart.getTime())/60000));activeStart=undefined;}
  }
  worked=Math.max(0,worked-breaks);
  const missingPunch=Boolean(activeStart||breakStart||(!ordered.some(e=>e.kind==='CLOCK_IN')!==!ordered.some(e=>e.kind==='CLOCK_OUT')));
  return {firstClockIn:ordered.find(e=>e.kind==='CLOCK_IN')?.capturedAt,lastClockOut:[...ordered].reverse().find(e=>e.kind==='CLOCK_OUT')?.capturedAt,workedMinutes:worked,breakMinutes:breaks,missingPunch,sourceEventIds:ordered.map(e=>e.id)};
}
