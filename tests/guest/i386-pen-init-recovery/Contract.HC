#ifndef PC_TRIALS
#define PC_TRIALS 8
#endif
#include "/Kernel/I386/Scheduler.HH"
#include "/Kernel/I386/MemoryBacking.HH"
U8 **pc_slot,**pc_scope_head;
Bool *pc_ready;
CTask **pc_builder,*pc_child;
CI386Heap *pc_heap;CI386BackingPool *pc_pool;
CDC *pc_dc;
U8 *(*pc_original)(I64 size,CTask *task);
I64 pc_target,pc_mode,pc_calls,pc_outcome,pc_values[PC_TRIALS*24];
Bool pc_hit,pc_done;
U0 PCLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *PCAlloc(I64 size,CTask *task)
{
  if(Fs==pc_child && ++pc_calls==pc_target) {
    pc_hit=TRUE;
    if(!pc_mode)throw('PenFail',TRUE);
    if(pc_mode==2)Exit;
    while(TRUE)Yield;
  }
  return (*pc_original)(size,task);
}
U0 PCChild(U8 *)
{
  pc_child=Fs;
  try {GrFillCircle(pc_dc,16,16,0,9);pc_outcome=1;}
  catch {if(Fs->except_ch=='PenFail'){pc_outcome=2;Fs->catch_except=TRUE;}}
  pc_done=TRUE;
  while(TRUE)Yield;
}
Bool PCEmpty()
{
  I64 i,j;
  for(i=0;i<GR_PEN_BRUSHES_NUM;i++) {
    if(gr.pen_brushes[i]||gr.collision_pen_brushes[i]||gr.even_pen_brushes[i]||gr.odd_pen_brushes[i])return FALSE;
    for(j=0;j<GR_PEN_BRUSHES_NUM;j++)if(gr.circle_lo[i][j]||gr.circle_hi[i][j])return FALSE;
  }
  return TRUE;
}
U0 PCBacking(I64 *v)
{
  CI386BackingRegion *r=pc_pool->owned;
  CI386HeapBlock *block;
  U8 *record;
  I64 count=0;
  MemSet(v,0,32);
  if(pc_pool->backing_signature!=I386_BACKING_SIGNATURE||pc_pool->heap!=pc_heap)throw('PCPool',TRUE);
  while(r) {
    if(++count>pc_pool->owned_count)throw('PCChain',TRUE);
    record=r;block=record-sizeof(CI386HeapBlock);
    if(block->tag!=I386_HEAP_USED||block->span!=r->span||block->requested!=r->request)throw('PCBlock',TRUE);
    if(record>=pc_heap->base&&record<pc_heap->base+pc_heap->size){v[0]+=r->span;v[1]++;}
    else {v[2]+=r->span;v[3]++;}
    r=r->next_owned;
  }
  if(count!=pc_pool->owned_count||v[0]+v[2]!=pc_pool->retained)throw('PCSum',TRUE);
}
U0 PCRun(I64 mode,I64 target,I64 *v=NULL)
{
  I64 deadline=cnts.jiffies+20000,used=pc_heap->used,allocations=pc_heap->allocations;
  I64 root=adam_task->data_heap->used_u8s,caller=Fs->data_heap->used_u8s;
  I64 backing[4],after[4];PCBacking(backing);
  U8 *scope=*pc_scope_head;
  CTask *task;
  Bool retired;
  pc_mode=mode;pc_target=target;pc_calls=pc_outcome=0;pc_hit=pc_done=FALSE;pc_child=NULL;
  task=Spawn(&PCChild,NULL,"Pen fault",-1,Fs,131072);
  while(!(mode&&pc_hit || !mode&&pc_done)&&cnts.jiffies<deadline)Yield;
  if(!(mode&&pc_hit || !mode&&pc_done))throw('PCWait',TRUE);
  if(mode==2) {
    while(TaskValidate(task)&&cnts.jiffies<deadline)Yield;
    retired=!TaskValidate(task);
  } else retired=Kill(task);
  Sleep(100);PCBacking(after);
  if(v) {
    v[0]=mode;v[1]=target;v[2]=pc_calls;v[3]=pc_outcome;
    v[4]=used;v[5]=allocations;v[6]=pc_heap->used;v[7]=pc_heap->allocations;
    v[8]=root;v[9]=adam_task->data_heap->used_u8s;
    v[10]=caller;v[11]=Fs->data_heap->used_u8s;
    v[12]=PCEmpty;v[13]=!*pc_ready && !*pc_builder;v[14]=retired;v[15]=*pc_scope_head==scope;
    v[16]=backing[0];v[17]=after[0];v[18]=backing[1];v[19]=after[1];
    v[20]=backing[2];v[21]=after[2];v[22]=backing[3];v[23]=after[3];
  }
}
U0 PCProbe()
{
  CI386Task *native=Fs;
  Bool suspended;
  I64 i,target;
  U8 *s;
  pc_heap=native->memory;
  if(!pc_heap||pc_heap->signature!=I386_HEAP_MAGIC||!PCEmpty||*pc_ready||*pc_builder)throw('PCState',TRUE);
  while(Bt(&sys_semas[SEMA_REFRESH_IN_PROGRESS],0))Yield;
  suspended=Suspend(sys_winmgr_task);
  pc_original=pc_slot[0];pc_dc=NULL;
  try {
    pc_dc=DCNew(32,32);pc_slot[0]=&PCAlloc;
    PCRun(0,256);PCRun(0,256);
    for(i=0;i<PC_TRIALS;i++) {
      switch(i%4){case 0:target=1;break;case 1:target=33;break;case 2:target=128;break;case 3:target=256;break;}
      PCRun(i/4,target,pc_values+i*24);
    }
    pc_slot[0]=pc_original;DCDel(pc_dc);pc_dc=NULL;
    Suspend(sys_winmgr_task,suspended);
  } catch {
    pc_slot[0]=pc_original;DCDel(pc_dc);Suspend(sys_winmgr_task,suspended);
  }
  s=MStrPrint("EXPORT pen-recovery.bin %X %X\n",pc_values,sizeof(pc_values));PCLog(s);Free(s);
  PCLog("PEN RECOVERY DONE\n");
}
