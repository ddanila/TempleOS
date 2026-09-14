#include "/Compiler/I386/InternalTypes.HH"
#include "/Compiler/InternalTypes.HC"
#include "/Compiler/I386/SymbolAlloc.HH"
#include "/Compiler/I386/SymbolDelete.HH"
#include "/Kernel/I386/Cpu.HH"
Bool I386InternalTypesDelete(CI386InternalTypes *registry)
{
  I64 i;
  CHash *entry;
  if(!registry) return FALSE;
  if(registry->table) {
    if(!I386HashTableValid(registry->heap,registry->table) || registry->table->locked_flags) return FALSE;
    for(i=0;i<=registry->table->mask;i++) while(entry=registry->table->body[i]) {
      if(!I386HashTableRemove(registry->heap,registry->table,entry) ||
          !I386HashDel(registry->heap,entry)) return FALSE;
    }
    if(!I386HashTableDelete(registry->heap,registry->table)) return FALSE;
  }
  registry->table=0; registry->heap=0;
  for(i=0;i<RT_RTS_NUM;i++) registry->by_raw[i]=0;
  return TRUE;
}
Bool I386InternalTypesInit(CI386InternalTypes *registry,CI386Heap *heap)
{
  I64 i,j;
  U32 flags;
  CHashClass *record;
  if(!registry || registry->table || registry->heap) return FALSE;
  for(i=0;i<RT_RTS_NUM;i++) if(registry->by_raw[i]) return FALSE;
  registry->table=I386HashTableNew(heap,32);
  if(!registry->table) return FALSE;
  registry->heap=heap;
  for(i=0;i<INTERNAL_TYPES_NUM;i++) {
    record=I386PrsClassNew(heap);
    if(!record) goto fail;
    InternalTypeSet(record,i);
    flags=I386IrqSave;
    record->str=I386HeapAlloc(heap,8,TRUE);
    I386IrqRestore(flags);
    if(!record->str) { I386HashDel(heap,record); goto fail; }
    for(j=0;j<8;j++) record->str[j]=internal_types_table[i].name[j];
    HashAdd(record,registry->table);
    registry->by_raw[record->raw_type]=record;
  }
  return TRUE;
fail:
  I386InternalTypesDelete(registry);
  return FALSE;
}
