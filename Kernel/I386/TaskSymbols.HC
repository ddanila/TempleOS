#include "/Kernel/I386/TaskSymbols.HH"
#include "/Compiler/I386/SymbolDelete.HH"
#include "/Kernel/I386/Cpu.HH"
#define I386_TASK_SYMBOLS_MAGIC 0x54535931
CI386TaskSymbols *I386TaskSymbolsValid(CI386Task *task)
{
  CI386TaskSymbols *state;
  if(!task || !(state=task->symbol_state) || state->signature!=I386_TASK_SYMBOLS_MAGIC ||
      state->task!=task || state->table!=task->hash_table || !state->table ||
      task->symbol_clone!=&I386TaskSymbolsClone || task->symbol_destroy!=&I386TaskSymbolsDestroy ||
      I386HeapSize(state->heap,state)!=sizeof(CI386TaskSymbols)) return 0;
  return state;
}
Bool I386TaskSymbolsInit(CI386Task *task,CI386Heap *heap,CHashTable *table,I64 buckets=1024)
{
  U32 flags=I386IrqSave;
  CI386TaskSymbols *state;
  Bool result=FALSE;
  if(!task || !task->owner || task!=task->owner->root || task!=task->owner->current ||
      task->hash_table || task->symbol_state || task->symbol_clone || task->symbol_destroy ||
      !table || buckets<1 || buckets>0x3FFFFFFF || buckets&(buckets-1)) goto symbols_init_done;
  state=I386HeapAlloc(heap,sizeof(CI386TaskSymbols),TRUE);
  if(!state) goto symbols_init_done;
  state->task=task; state->heap=heap; state->table=table; state->buckets=buckets;
  state->signature=I386_TASK_SYMBOLS_MAGIC;
  task->hash_table=table; task->symbol_state=state;
  task->symbol_clone=&I386TaskSymbolsClone; task->symbol_destroy=&I386TaskSymbolsDestroy;
  result=TRUE;
symbols_init_done:
  I386IrqRestore(flags); return result;
}
Bool I386TaskSymbolsClone(CI386Task *source,CI386Task *target,CI386Heap *heap)
{
  U32 flags=I386IrqSave;
  CI386TaskSymbols *parent=I386TaskSymbolsValid(source),*state;
  CHashTable *table;
  Bool result=FALSE;
  if(!parent || !target || target->owner || target->hash_table || target->symbol_state ||
      target->symbol_clone || target->symbol_destroy || parent->children==0xFFFFFFFF ||
      source->lifetime_refs==0xFFFFFFFF) goto symbols_clone_done;
  state=I386HeapAlloc(heap,sizeof(CI386TaskSymbols),TRUE);
  if(!state) goto symbols_clone_done;
  table=I386HashTableNew(heap,parent->buckets);
  if(!table) { I386HeapFree(heap,state); goto symbols_clone_done; }
  table->next=parent->table;
  state->task=target; state->parent=parent; state->heap=heap; state->table=table;
  state->buckets=parent->buckets; state->signature=I386_TASK_SYMBOLS_MAGIC;
  parent->children++; source->lifetime_refs++;
  target->hash_table=table; target->symbol_state=state;
  target->symbol_clone=&I386TaskSymbolsClone; target->symbol_destroy=&I386TaskSymbolsDestroy;
  result=TRUE;
symbols_clone_done:
  I386IrqRestore(flags); return result;
}
Bool I386TaskSymbolsDestroy(CI386Task *task)
{
  U32 flags=I386IrqSave;
  CI386TaskSymbols *state=I386TaskSymbolsValid(task),*parent;
  CHashTable *table;
  CHash *entry;
  I64 i;
  Bool result=FALSE;
  if(!state || state->children || task->lifetime_refs ||
      (task->owner && !task->finished && task->owner->current!=task && task->owner->current!=task->owner->root)) goto symbols_destroy_done;
  parent=state->parent; table=state->table;
  if(parent) {
    if(I386TaskSymbolsValid(parent->task)!=parent || !parent->children || !parent->task->lifetime_refs ||
        table->next!=parent->table || !I386HashTableValid(state->heap,table) || table->locked_flags) goto symbols_destroy_done;
    //Exclusive, valid owned symbol graph. Failed release is corruption, not rollback.
    for(i=0;i<=table->mask;i++)
      while(entry=table->body[i]) {
        table->body[i]=entry->next; entry->next=0;
        if(!I386HashDel(state->heap,entry)) goto symbols_destroy_done;
      }
    table->next=0;
    if(!I386HashTableDelete(state->heap,table)) goto symbols_destroy_done;
  }
  if(!I386HeapFree(state->heap,state)) goto symbols_destroy_done;
  if(parent) { parent->children--; parent->task->lifetime_refs--; }
  task->hash_table=0; task->symbol_state=0; task->symbol_clone=0; task->symbol_destroy=0;
  result=TRUE;
symbols_destroy_done:
  I386IrqRestore(flags); return result;
}
