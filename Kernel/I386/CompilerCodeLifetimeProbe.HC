//A real child publishes executable storage, yields, exits and is reaped by its parent.
class CProbeCodeLifetime {
  CI386CompilerProbe *probe;
  I64 answer;
  U32 stage,flags;
  I64 (*code)();
};
U0 ProbeCodeAnswer(U8 *context,I64 value,CHashClass *type)
{
  CProbeCodeLifetime *state=context;
  state->answer=value;
}
U0 ProbeCodeChild(I64 argument)
{
  CProbeCodeLifetime *state=argument;
  CI386Task *task=I386TaskSelf;
  CI386CommandInput input;
  CI386TaskSymbols *scope=task->symbol_state;
  CHashFun *fun=0;
  CHash *entry;
  I64 i;
  U8 *bytes=&input;
  for(i=0;i<sizeof(CI386CommandInput);i++) bytes[i]=0;
  input.heap=scope->heap; input.types=state->probe->internal_types;
  input.files=state->probe->files; input.includes=state->probe->disk_include;
  input.source="I64i ReapCode(){return 42;}ReapCode;";
  input.filename="C:/Probe/ReapCode.HC"; input.context=state; input.answer=&ProbeCodeAnswer;
  SetRFlags((GetRFlags&~0x200)|(state->flags&0x200));
  Bool accepted=state->probe->compiler->input(&input);
  KernelLog("CODE CHILD INPUT "); KernelHex(accepted); KernelLog(" ");
  KernelHex(state->answer); KernelLog(" "); KernelHex(input.commands); KernelLog(" ");
  KernelHex(input.answers); KernelLog(" "); KernelHex(input.exception); KernelLog("\n");
  if(!accepted || state->answer!=42 || input.commands!=1 ||
      input.answers!=1 || task->active_controls || task->last_cc!=&task->next_cc) KernelStop;
  for(i=0;i<=scope->table->mask;i++)
    for(entry=scope->table->body[i];entry;entry=entry->next)
      if(!StrCmp(entry->str,"ReapCode")) fun=entry;
  if(!fun || !(fun->type&HTT_FUN) || !fun->exe_addr || !scope->storage ||
      (fun->exe_addr-offset(CMemUsed.start))(CMemUsed *)->hc!=task->code_heap) KernelStop;
  KernelLog("CODE CHILD PUBLISHED\n");
  state->code=fun->exe_addr; state->stage=1;
  if(!I386SchedYield(task->owner) || (*state->code)()!=42 || (GetRFlags&0x200)!=(state->flags&0x200)) KernelStop;
  state->stage=2;
}
U0 ProbeCodeLifetime(CI386CompilerProbe *probe)
{
  CI386Task *parent=I386TaskSelf;
  CI386TaskSymbols *scope;
  CI386OwnedTask *child;
  CProbeCodeLifetime state;
  I64 used=probe->heap->used,allocations=probe->heap->allocations,refs=parent->lifetime_refs;
  U32 flags=GetRFlags;
  state.probe=probe; state.flags=flags; state.answer=0; state.stage=0; state.code=0;
  child=I386TaskSpawn(parent->owner,probe->heap,8192,&ProbeCodeChild,&state);
  if(!child) KernelStop;
  KernelLog("CODE CHILD SPAWNED\n");
  child->task.memory=probe->heap;
  while(!state.stage) if(!I386SchedYield(parent->owner)) KernelStop;
  scope=child->task.symbol_state;
  if(state.stage!=1 || child->task.finished || (*state.code)()!=42 || I386TaskDestroy(child)) KernelStop;
  child->task.code_heap->locked_flags=1;
  while(!child->task.finished) if(!I386SchedYield(parent->owner)) KernelStop;
  if(state.stage!=2 || I386TaskDestroy(child) || child->task.symbol_state!=scope ||
      child->task.hash_table!=scope->table || !scope->storage || (*state.code)()!=42) KernelStop;
  KernelLog("CODE CHILD DEFERRED\n");
  child->task.code_heap->locked_flags=0;
  if(!I386TaskDestroy(child) || probe->heap->used!=used || probe->heap->allocations!=allocations ||
      parent->lifetime_refs!=refs || !I386HeapValid(probe->heap) ||
      (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  KernelLog("CODE HEAP LIFETIME "); KernelHex(probe->phase); KernelLog("\n");
}
