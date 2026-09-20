#include "/Kernel/I386/AtaChannel.HH"
class CProbeFileBreak {
  CI386CompilerProbe *probe;
  U32 flags,done;
  I64 answer;
};
U0 ProbeFileBreakAnswer(U8 *context,I64 value,CHashClass *type)
{
  CProbeFileBreak *state=context;
  state->answer=value;
}
U0 ProbeFileBreakChild(I64 argument)
{
  CProbeFileBreak *state=argument;
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  CI386TaskFiles *files=task->file_state;
  CI386CommandInput input;
  U8 *bytes=&input,*data,*name=0;
  I64 i,size,attr,used=scope->heap->used,allocations=scope->heap->allocations;
  Bool caught=FALSE;
  for(i=0;i<sizeof(CI386CommandInput);i++) bytes[i]=0;
  input.heap=scope->heap; input.types=state->probe->internal_types;
  input.files=state->probe->files; input.includes=state->probe->disk_include;
  input.filename="C:/Probe/FileBreak.HC";
  input.source="I64i FileBreakPrivate(){return 99;}\n#include \"C:/Probe/Outer\"\n";
  input.context=state; input.answer=&ProbeFileBreakAnswer;
  SetRFlags((GetRFlags&~0x200)|state->flags);
  try { state->probe->compiler->input(&input); KernelStop; }
  catch {
    if(task->except_ch!='Break' || input.exception!='Break' || task->wait ||
        task->io_locks || task->lifetime_refs || task->active_controls || files->busy ||
        task->last_cc!=&task->next_cc || task->task_flags&(1<<TASKf_PENDING_BREAK) ||
        (GetRFlags&0x200)!=state->flags) KernelStop;
    task->catch_except=TRUE; caught=TRUE;
  }
  if(!caught || task->except_top || scope->heap->used!=used ||
      scope->heap->allocations!=allocations || scope->storage ||
      ProbeSymbolFind(0,"FileBreakPrivate",scope->table,HTT_FUN)) KernelStop;
  KernelLog("FILE BREAK CAUGHT\n");
  data=state->probe->files->read(scope->heap,"C:/Probe/Outer.HC",&size,&attr,&name);
  if(!data || !name || size<1 || files->busy || task->lifetime_refs || task->io_locks ||
      !I386HeapFree(scope->heap,data) || !I386HeapFree(scope->heap,name)) KernelStop;
  KernelLog("FILE BREAK READ OK\n");
  input.source="6*7;";
  if(!state->probe->compiler->input(&input) || state->answer!=42 || input.answers!=1 ||
      task->wait || task->active_controls || task->lifetime_refs || files->busy ||
      scope->heap->used!=used || scope->heap->allocations!=allocations ||
      (GetRFlags&0x200)!=state->flags) KernelStop;
  state->done=1;
}
U0 ProbeFileBreak(CI386CompilerProbe *probe)
{
  CI386Task *parent=I386TaskSelf,*task;
  CI386OwnedTask *child;
  CI386TaskFiles *files;
  CI386AtaChannel *channel;
  CProbeFileBreak state;
  I64 scenario,round,used=probe->heap->used,allocations=probe->heap->allocations;
  I64 refs=parent->lifetime_refs;
  U32 flags=GetRFlags;
  for(scenario=0;scenario<2;scenario++) {
    state.probe=probe; state.flags=scenario*0x200; state.done=0; state.answer=0;
    KernelLog("FILE BREAK START "); KernelHex(scenario); KernelLog("\n");
    if(!I386RedSeaBegin(probe->volume) || parent->io_locks!=1) KernelStop;
    child=I386TaskSpawn(parent->owner,probe->heap,16384,&ProbeFileBreakChild,&state);
    if(!child) KernelStop;
    task=&child->task; task->memory=probe->heap;
    files=task->file_state;
    for(round=0;round<64 && !task->blocked && !task->finished;round++)
      if(!I386SchedYield(parent->owner)) KernelStop;
    if(task->finished || !task->blocked || !task->wait || task->wait->kind!=I386_WAIT_ATA ||
        !files || !files->busy || task->lifetime_refs<=task->active_controls) KernelStop;
    KernelLog("FILE BREAK QUEUED\n");
    channel=task->wait->object;
    if(!channel || channel->owner!=parent || !channel->head || task->io_locks) KernelStop;
    if(scenario && !I386TaskBreakLock(task)) KernelStop;
    if(!I386TaskBreakRequest(task)) KernelStop;
    if(scenario) {
      if(!task->blocked || task->wait->cancelled || !files->busy || channel->owner!=parent ||
          !I386TaskBreakUnlock(task)) KernelStop;
    }
    if(task->blocked || !task->wait->cancelled || !files->busy ||
        task->lifetime_refs<=task->active_controls || channel->owner!=parent ||
        parent->io_locks!=1 || channel->head || channel->tail ||
        !I386TaskBreakRequest(task) || !I386RedSeaEnd(probe->volume)) KernelStop;
    while(!task->finished) if(!I386SchedYield(parent->owner)) KernelStop;
    if(!state.done || channel->owner || channel->head || channel->poisoned ||
        !I386TaskDestroy(child) || parent->io_locks || parent->lifetime_refs!=refs ||
        probe->heap->used!=used || probe->heap->allocations!=allocations ||
        !I386HeapValid(probe->heap) || (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
    KernelLog("FILE BREAK CLEANUP "); KernelHex(scenario); KernelLog("\n");
  }
}
