#ifndef I386_TASK_EXTERN_IMPLEMENTED
#define I386_TASK_EXTERN_IMPLEMENTED
#include "/Kernel/I386/TaskSymbols.HH"
#include "/Kernel/SymbolTypes.HH"
Bool I386TaskExternUsageValid(CI386Heap *heap,CI386TaskExternUsage *usage)
{
  CI386TaskSymbols *scope;
  I64 bytes;
  if(!usage || I386HeapSize(heap,usage)<sizeof(CI386TaskExternUsage) ||
      usage->signature!=I386_TASK_EXTERN_MAGIC ||
      usage->argument_count<0 || usage->argument_count>4095 ||
      I386HeapSize(heap,usage)!=sizeof(CI386TaskExternUsage)+
        usage->argument_count*sizeof(CHashClass *) ||
      !(scope=usage->scope) || I386HeapSize(heap,scope)!=sizeof(CI386TaskSymbols) ||
      scope->signature!=I386_TASK_SYMBOLS_MAGIC || scope->heap!=heap ||
      !usage->function || I386HeapSize(heap,usage->function)!=sizeof(CHashFun)*(PTR_STARS_NUM+1) ||
      !usage->code || !usage->undefined_address || !usage->indirect ||
      usage->code_bytes<1 || usage->offset<2 ||
      usage->offset>usage->code_bytes-4 || usage->rip!=(usage->code+usage->offset+0)(U64))return FALSE;
  if(usage->code_owner) {
    if(I386HeapSize(heap,usage->code_owner)!=sizeof(CI386TaskHeaps) ||
        !usage->code_owner->code_capacity ||
        usage->code_owner->control.locked_flags || usage->code_owner->control.bp->locked_flags)
      return FALSE;
    bytes=(*usage->code_owner->code_capacity)(usage->code_owner,usage->code);
  } else bytes=I386HeapSize(heap,usage->code);
  return bytes>=usage->code_bytes && usage->code[usage->offset-2]==0xFF &&
    usage->code[usage->offset-1]==0x15 &&
    (usage->code+usage->offset)(U32 *)[0]==(&usage->function->exe_addr+0)(U64);
}
Bool I386TaskExternPendingFind(CI386Heap *heap,CI386TaskExternUsage *usage)
{
  CI386TaskExternUsage *node;
  I64 count=0;
  for(node=usage->scope->pending_externs;node;node=node->pending_next) {
    if(++count>heap->allocations || !I386TaskExternUsageValid(heap,node))return FALSE;
    if(node==usage)return TRUE;
  }
  return FALSE;
}
Bool I386TaskExternFunctionValid(CI386Heap *heap,CHashFun *function)
{
  CI386TaskExternUsage *usage=function->ext_lst;
  I64 count=0;
  while(usage) {
    if(++count>heap->allocations || !I386TaskExternUsageValid(heap,usage) ||
        usage->function!=function || !I386TaskExternPendingFind(heap,usage))return FALSE;
    usage=usage->next;
  }
  return TRUE;
}
U0 I386TaskExternPendingRemove(CI386TaskExternUsage *usage)
{//Caller preflighted both lists and holds interrupt exclusion.
  CI386TaskExternUsage **link=&usage->scope->pending_externs;
  while(*link && *link!=usage)link=&(*link)->pending_next;
  if(*link==usage)*link=usage->pending_next;
  usage->pending_next=0;usage->scope=0;
}
Bool I386TaskExternSymbolDetach(CI386Heap *heap,CHashSrcSym *symbol)
{//HashDel of an unresolved target must not leave caller-owned dangling links.
  CHashFun *function;
  CI386TaskExternUsage *usage,*next;
  if(!symbol || !(symbol->type&HTT_FUN))return TRUE;
  function=symbol;
  if(!I386TaskExternFunctionValid(heap,function))return FALSE;
  for(usage=function->ext_lst;usage;usage=next) {
    next=usage->next;
    //Retire an indirect descriptor borrow before HashDel frees that descriptor.
    //CALL rel32 plus NOP occupies the same six bytes and invokes real UndefExt.
    usage->code[usage->offset-2]=0xE8;
    (usage->code+usage->offset-1)(U32 *)[0]=(usage->undefined_address+0)(U64)-
      (usage->code+usage->offset+3)(U64);
    usage->code[usage->offset+3]=0x90;
    I386TaskExternPendingRemove(usage);usage->next=0;
  }
  function->ext_lst=0;return TRUE;
}
Bool I386TaskExternScopeValid(CI386Heap *heap,CI386TaskSymbols *scope)
{
  CI386TaskExternUsage *usage,*node;
  I64 count=0,links;
  for(usage=scope->pending_externs;usage;usage=usage->pending_next) {
    if(++count>heap->allocations || !I386TaskExternUsageValid(heap,usage) || usage->scope!=scope)return FALSE;
    links=0;
    for(node=usage->function->ext_lst;node && node!=usage;node=node->next)
      if(++links>heap->allocations || !I386TaskExternUsageValid(heap,node))return FALSE;
    if(node!=usage)return FALSE;
  }
  return TRUE;
}
U0 I386TaskExternScopeDetach(CI386TaskSymbols *scope)
{//A dying child retires call sites before its code or inherited parent can die.
  CI386TaskExternUsage *usage,**link;
  while(usage=scope->pending_externs) {
    link=&usage->function->ext_lst;
    while(*link && *link!=usage)link=&(*link)->next;
    if(*link==usage)*link=usage->next;
    I386TaskExternPendingRemove(usage);usage->next=0;
  }
}
#endif
