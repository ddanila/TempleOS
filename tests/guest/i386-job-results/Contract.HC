I64 JRContract()
{
  CJobCtrl ctrl;
  CJob *job;
  I64 result=123,mask=0,base=Fs->data_heap->used_u8s;
  if(Fs->srv_ctrl.next_done!=&Fs->srv_ctrl.next_done)return 0;
  ctrl.next_waiting=ctrl.last_waiting=&ctrl.next_waiting;
  ctrl.next_done=ctrl.last_done=&ctrl.next_done;ctrl.flags=0;
  if(!JobResScan(NULL,&result)&&!result)mask|=1;
  job=CAlloc(sizeof(CJob));job->ctrl=&ctrl;result=123;
  if(!JobResScan(job,&result)&&!result)mask|=2;
  JobDel(job);
  job=CAlloc(sizeof(CJob));job->master_task=Fs;job->ctrl=&ctrl;
  job->res=42;LBts(&job->flags,JOBf_DONE);
  QueIns(job,Fs->srv_ctrl.last_done);
  if(JobResScan(job,&result)&&result==42&&Fs->srv_ctrl.next_done==&Fs->srv_ctrl.next_done)mask|=4;
  job=CAlloc(sizeof(CJob));job->ctrl=&ctrl;job->res=-7;
  LBts(&job->flags,JOBf_DONE);QueIns(job,ctrl.last_done);
  if(JobResScan(job,&result)&&result==-7&&ctrl.next_done==&ctrl.next_done)mask|=8;
  job=CAlloc(sizeof(CJob));job->ctrl=&Fs->srv_ctrl;job->res=99;
  LBts(&job->flags,JOBf_DONE);QueIns(job,Fs->srv_ctrl.last_done);
  if(JobResScan(NULL,&result)&&result==99&&Fs->srv_ctrl.next_done==&Fs->srv_ctrl.next_done)mask|=16;
  if(Fs->data_heap->used_u8s==base&&!Bt(&ctrl.flags,JOBCf_LOCKED)&&!Bt(&Fs->srv_ctrl.flags,JOBCf_LOCKED))mask|=32;
  return mask;
}
