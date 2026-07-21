import { Worker } from 'bullmq';
import IORedis from 'ioredis';
const connection = new IORedis(process.env.REDIS_URL ?? 'redis://localhost:6379', { maxRetriesPerRequest:null });
const worker = new Worker('geoattend-jobs', async job => {
  switch(job.name){
    case 'attendance-summary': return { employeeId:job.data.employeeId, processedAt:new Date().toISOString() };
    case 'payroll-calculate': return { payrollRunId:job.data.payrollRunId, queued:true };
    default: throw new Error(`Unknown job: ${job.name}`);
  }
}, { connection });
worker.on('completed', job => console.log(JSON.stringify({level:'info',message:'job completed',jobId:job.id,name:job.name})));
worker.on('failed', (job,error) => console.error(JSON.stringify({level:'error',message:'job failed',jobId:job?.id,error:error.message})));
process.on('SIGTERM', async()=>{ await worker.close(); await connection.quit(); });
