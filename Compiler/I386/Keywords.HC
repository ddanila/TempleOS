#include "/Compiler/I386/Keywords.HH"
#include "/Compiler/KeywordTable.HC"
#include "/Compiler/I386/SymbolDelete.HH"
#include "/Kernel/I386/Cpu.HH"
Bool I386KeywordsDelete(CI386Keywords *registry)
{
  I64 i; CHash *entry;
  if(!registry) return FALSE;
  if(registry->table) {
    if(!I386HashTableValid(registry->heap,registry->table) || registry->table->locked_flags) return FALSE;
    for(i=0;i<=registry->table->mask;i++) while(entry=registry->table->body[i]) {
      if(!I386HashTableRemove(registry->heap,registry->table,entry) || !I386HashDel(registry->heap,entry)) return FALSE;
    }
    if(!I386HashTableDelete(registry->heap,registry->table)) return FALSE;
  }
  registry->table=0; registry->heap=0;
  return TRUE;
}
Bool I386KeywordsInit(CI386Keywords *registry,CI386Heap *heap)
{
  CHashGeneric *entry; CCompilerKeyword *descriptor; I64 i,j,length; U32 flags;
  if(!registry || registry->table || registry->heap) return FALSE;
  registry->table=I386HashTableNew(heap,64);
  if(!registry->table) return FALSE;
  registry->heap=heap;
  for(i=0;i<COMPILER_KEYWORDS_NUM;i++) {
    descriptor=compiler_keywords+i; length=0;
    while(descriptor->name[length]) length++;
    flags=I386IrqSave;
    entry=I386HeapAlloc(heap,sizeof(CHashGeneric),TRUE);
    if(entry) {
      entry->str=I386HeapAlloc(heap,length+1,FALSE);
      if(!entry->str) { I386HeapFree(heap,entry); entry=0; }
    }
    I386IrqRestore(flags);
    if(!entry) { I386KeywordsDelete(registry); return FALSE; }
    for(j=0;j<=length;j++) entry->str[j]=descriptor->name[j];
    entry->type=descriptor->type; entry->user_data0=descriptor->value;
    HashAdd(entry,registry->table);
  }
  return TRUE;
}
