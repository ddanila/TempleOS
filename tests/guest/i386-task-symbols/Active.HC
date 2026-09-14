//Task-exit cleanup, queue ordering, detached survival and recoverable rejection.
CI386OwnedTask *active_worker;
CCmpCtrl *active_first,*active_second;
I64 active_order,active_callbacks,active_user_cleanup;
U32 active_flags;
U0 ActiveUserCleanup(CI386Task *task)
{
  if(task!=I386TaskSelf || !task->finishing || active_callbacks ||
      I386TaskCmpCtrlNew(&task_compiler) || I386CmpCtrlEnter(task->memory,active_first)) errors++;
  active_user_cleanup++;
}
U0 ActiveDocument(U8 *context,CDoc *document)
{
  CI386Task *task=context;
  if(active_user_cleanup!=1 || task!=&active_worker->task || !task->lifetime_refs || !task->compiler_busy ||
      (GetRFlags&0x200)!=active_flags || I386TaskDestroy(active_worker) ||
      I386CmpCtrlDrain(task) || I386TaskSymbolsDestroy(task)) errors++;
  if(task->active_controls &&
      (I386CmpCtrlLeave(task->memory,task->last_cc) || I386CmpCtrlDel(task->memory,task->last_cc))) errors++;
  active_order=active_order*10+(document+0)(U32);
  active_callbacks++;
  //Keep the owner pinned and the queue protected while another task runs.
  I386SchedYield(&scheduler);
}
U0 ActiveWorker(I64 phase)
{
  CI386Task *task=I386TaskSelf;
  SetRFlags((GetRFlags&~0x200)|active_flags);
  if(!I386SchedSetCleanup(&scheduler,&ActiveUserCleanup)) { errors++; return; }
  active_first=I386TaskCmpCtrlNew(&task_compiler);
  active_second=I386TaskCmpCtrlNew(&task_compiler);
  if(!active_first || !active_second) { errors++; return; }
  active_first->lex_include_stk->flags=LFSF_DOC; active_first->lex_include_stk->doc=1;
  active_second->lex_include_stk->flags=LFSF_DOC; active_second->lex_include_stk->doc=2;
  if(phase==2) {
    if(!I386CmpCtrlEnter(task->memory,active_first)) errors++;
  } else if(!I386CmpCtrlEnter(task->memory,active_first,&ActiveDocument,task)) errors++;
  if(!I386CmpCtrlEnter(task->memory,active_second,&ActiveDocument,task) ||
      I386CmpCtrlEnter(task->memory,active_second) || task->active_controls!=2 ||
      task->lifetime_refs!=2 || task->next_cc!=active_first || task->last_cc!=active_second ||
      (GetRFlags&0x200)!=active_flags) { errors++; return; }
  if(phase==1) {
    //Removal need not be LIFO. The detached control retains its owner pin.
    if(!I386CmpCtrlLeave(task->memory,active_first) || task->active_controls!=1 ||
        task->lifetime_refs!=2 || active_first->next!=active_first || active_first->last!=active_first ||
        I386CmpCtrlLeave(task->memory,active_first)) errors++;
  }
}
I64 ActiveTest()
{
  I64 phase,enabled,round,used=heap.used,allocations=heap.allocations;
  U32 flags=GetRFlags;
  for(enabled=0;enabled<2;enabled++) for(phase=0;phase<3;phase++) {
    active_flags=enabled*0x200; active_order=0; active_callbacks=0; active_user_cleanup=0;
    active_worker=I386TaskSpawn(&scheduler,&heap,4096,&ActiveWorker,phase,0x18,0x20,16384);
    if(!active_worker) return 30;
    for(round=0;round<20 && !active_worker->task.finished;round++) I386SchedYield(&scheduler);
    if(!active_worker->task.finished || active_user_cleanup!=1 || errors || active_worker->task.compiler_busy) return 31;
    if(!phase) {
      if(active_order!=21 || active_callbacks!=2 || active_worker->task.lifetime_refs ||
          active_worker->task.active_controls || active_worker->task.compiler_cleanup_failed) return 32;
    } else {
      if(I386TaskDestroy(active_worker)) return 33;
      if(phase==1) {
        if(active_order!=2 || active_callbacks!=1 || active_worker->task.lifetime_refs!=1 ||
            active_worker->task.active_controls || active_worker->task.compiler_cleanup_failed) return 34;
      } else {
        if(active_order || active_callbacks || active_worker->task.lifetime_refs!=2 ||
            active_worker->task.active_controls!=2 || !active_worker->task.compiler_cleanup_failed ||
            I386CmpCtrlDrain(&active_worker->task) || I386CmpCtrlDel(active_worker->task.memory,active_first)) return 35;
      }
      SetRFlags((flags&~0x200)|active_flags);
      if(phase==2 && (!I386CmpCtrlUnwind(&active_worker->task,active_first) ||
          active_worker->task.active_controls!=1 || active_worker->task.lifetime_refs!=1 ||
          !active_worker->task.compiler_cleanup_failed || active_callbacks!=1 || active_order!=2 ||
          I386TaskDestroy(active_worker))) return 40;
      if(!I386CmpCtrlDel(active_worker->task.memory,active_first,&ActiveDocument,&active_worker->task)) return 36;
      if(phase==2 && !I386CmpCtrlDrain(&active_worker->task)) return 37;
      SetRFlags(flags);
      if(active_callbacks!=2 || active_worker->task.lifetime_refs || active_worker->task.active_controls ||
          active_worker->task.compiler_cleanup_failed || errors) return 38;
    }
    if(!I386TaskDestroy(active_worker) || root.lifetime_refs || heap.used!=used ||
        heap.allocations!=allocations || !I386HeapValid(&heap)) return 39;
  }
  return 0;
}
