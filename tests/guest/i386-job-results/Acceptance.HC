U0 JRPopup(U8 *data){while(TRUE)Yield;}
I64 JRContract()
{
  CJob *job;
  CTask *popup=Fs->popup_task,*child;
  I64 mask=0,flags=GetRFlags,base,root;
  Bool old_filter=Bt(&Fs->task_flags,TASKf_FILTER_INPUT);
  if(popup)return 0;
  child=Spawn(&JRPopup,NULL,"Popup rule",-1,Fs);
  SetRFlags(flags&~512);
  base=Fs->data_heap->used_u8s;root=adam_task->data_heap->used_u8s;
  if(!TaskExe(Fs,Fs,NULL,0))mask|=1;
  if(!TaskExe(NULL,Fs,"6*7;",0))mask|=2;
  Fs->popup_task=child;LBtr(&Fs->task_flags,TASKf_FILTER_INPUT);
  if(!TaskExe(Fs,Fs,"6*7;",0))mask|=4;
  LBts(&Fs->task_flags,TASKf_FILTER_INPUT);
  job=TaskExe(Fs,Fs,"6*7;",0);
  if(job){mask|=8;QueRem(job);JobDel(job);}
  Fs->popup_task=popup;
  if(!old_filter)LBtr(&Fs->task_flags,TASKf_FILTER_INPUT);
  job=TaskExe(Fs,NULL,"",0);
  if(job&&!job->aux_str[0]&&!job->master_task)mask|=16;
  if(job){QueRem(job);JobDel(job);}
  if(Fs->data_heap->used_u8s==base&&adam_task->data_heap->used_u8s==root&&
    Fs->srv_ctrl.next_waiting==&Fs->srv_ctrl.next_waiting&&!Bt(&Fs->srv_ctrl.flags,JOBCf_LOCKED))mask|=32;
  SetRFlags(flags);Kill(child);return mask;
}
