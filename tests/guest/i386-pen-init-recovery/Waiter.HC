U8 *pw_ensure_lo,*pw_ensure_hi;
CTask *pw_first,*pw_waiter;
CDC *pw_first_dc,*pw_waiter_dc;
Bool pw_hit,pw_release,pw_done;
I64 pw_first_calls,pw_waiter_calls,pw_values[32],pw_frames[16];
U8 *PWAlloc(I64 size,CTask *task)
{
  if(Fs==pw_first && ++pw_first_calls==33) {
    pw_hit=TRUE;
    while(!pw_release)Yield;
    Exit;
  }
  if(Fs==pw_waiter)pw_waiter_calls++;
  return (*pc_original)(size,task);
}
U0 PWFirst(U8 *)
{
  pw_first=Fs;GrFillCircle(pw_first_dc,16,16,0,9);
  throw('PWFirst',TRUE);
}
U0 PWWaiter(U8 *)
{
  pw_waiter=Fs;GrFillCircle(pw_waiter_dc,16,16,0,9);pw_done=TRUE;
  while(TRUE)Yield;
}
I64 PWCacheSpan()
{
  CDC *dc;U8 *ptr;I64 i,k,j,sum=0;
  for(i=0;i<GR_PEN_BRUSHES_NUM;i++)for(k=0;k<4;k++) {
    switch(k){case 0:dc=gr.pen_brushes[i];break;case 1:dc=gr.collision_pen_brushes[i];break;case 2:dc=gr.even_pen_brushes[i];break;case 3:dc=gr.odd_pen_brushes[i];break;}
    if(!dc||dc->mem_task!=adam_task)throw('PWOwner',TRUE);
    for(j=0;j<3;j++) {
      switch(j){case 0:ptr=dc;break;case 1:ptr=dc->r;break;case 2:ptr=dc->body;break;}
      if(ptr) {
        if(MHeapCtrl(ptr)!=adam_task->data_heap)throw('PWAlloc',TRUE);
        //MSize2 already includes the allocator header.
        sum+=MSize2(ptr);
      }
    }
  }
  return sum;
}
U0 PWProbe(I64 mode)
{
  CI386Task *native=Fs;
  CTask *first,*waiter,*old_first=Fs->next_child_task,*old_last=Fs->last_child_task;
  Bool paused,retired,waiter_retired;
  I64 i,found=-1,deadline=cnts.jiffies+20000,backing[4],after[4];
  U8 *scope,*s,*pc;
  pc_heap=native->memory;
  if(!PCEmpty||*pc_ready||*pc_builder)throw('PWState',TRUE);
  while(Bt(&sys_semas[SEMA_REFRESH_IN_PROGRESS],0))Yield;
  paused=Suspend(sys_winmgr_task);pc_original=pc_slot[0];scope=*pc_scope_head;
  //Settle first-use allocator/task state using the measured fault path.
  pc_dc=DCNew(32,32);pc_slot[0]=&PCAlloc;
  PCRun(0,256);PCRun(0,256);
  pc_slot[0]=pc_original;DCDel(pc_dc);pc_dc=NULL;
  if(!PCEmpty||*pc_ready||*pc_builder)throw('PWWarm',TRUE);
  //Measure both snapshots inside this try, including its live exception record.
  try {
    pw_values[0]=mode;pw_values[1]=33;pw_values[12]=adam_task->data_heap->used_u8s;
  pw_values[16]=Fs->data_heap->used_u8s;pw_values[20]=pc_heap->used;pw_values[22]=pc_heap->allocations;PCBacking(backing);
    pw_first_dc=DCNew(32,32);pw_waiter_dc=DCNew(32,32);
    pw_first=pw_waiter=NULL;pw_first_calls=pw_waiter_calls=0;pw_hit=pw_release=pw_done=FALSE;
    pc_slot[0]=&PWAlloc;first=Spawn(&PWFirst,NULL,"Pen owner",-1,Fs,131072);
    while(!pw_hit&&cnts.jiffies<deadline)Yield;
    if(!pw_hit||*pc_builder!=first)throw('PWHold',TRUE);
    waiter=Spawn(&PWWaiter,NULL,"Pen waiter",-1,Fs,131072);
    while(found<0&&cnts.jiffies<deadline) {
      Yield;
      for(i=0;i<16;i++) {
        pc=TaskCaller(waiter,i,TRUE);pw_frames[i]=pc;
        if(pc>=pw_ensure_lo&&pc<pw_ensure_hi)found=i;
      }
    }
    if(found<0||pw_done||pw_waiter_calls||*pc_builder!=first)throw('PWBlock',TRUE);
    pw_values[2]=pw_first_calls;pw_values[3]=pw_waiter_calls;
    pw_values[4]=pw_frames[found];pw_values[5]=found;
    if(mode) {
      pw_release=TRUE;
      while(TaskValidate(first)&&cnts.jiffies<deadline)Yield;
      retired=!TaskValidate(first);
    } else retired=Kill(first);
    while(!pw_done&&cnts.jiffies<deadline)Yield;
    if(!pw_done)throw('PWRetry',TRUE);
    pw_values[6]=retired;pw_values[7]=pw_done;pw_values[8]=pw_waiter_calls;
    pw_values[9]=*pc_ready;pw_values[10]=!*pc_builder;
    pw_values[14]=PWCacheSpan;pw_values[15]=1;
    waiter_retired=Kill(waiter);Sleep(100);
    pc_slot[0]=pc_original;DCDel(pw_first_dc);DCDel(pw_waiter_dc);
    pw_first_dc=pw_waiter_dc=NULL;
    pw_values[11]=*pc_scope_head==scope;pw_values[13]=adam_task->data_heap->used_u8s;
    pw_values[17]=Fs->data_heap->used_u8s;pw_values[18]=waiter_retired;
    pw_values[19]=Fs->next_child_task==old_first&&Fs->last_child_task==old_last;
    pw_values[21]=pc_heap->used;pw_values[23]=pc_heap->allocations;PCBacking(after);
    pw_values[24]=backing[0];pw_values[25]=after[0];pw_values[26]=backing[1];pw_values[27]=after[1];
    pw_values[28]=backing[2];pw_values[29]=after[2];pw_values[30]=backing[3];pw_values[31]=after[3];
    Suspend(sys_winmgr_task,paused);
  } catch {
    pc_slot[0]=pc_original;Suspend(sys_winmgr_task,paused);
  }
  s=MStrPrint("EXPORT pen-waiter.bin %X %X\n",pw_values,sizeof(pw_values));PCLog(s);Free(s);
  s=MStrPrint("EXPORT pen-waiter-frames.bin %X %X\n",pw_frames,sizeof(pw_frames));PCLog(s);Free(s);
  PCLog("PEN WAITER DONE\n");
}
