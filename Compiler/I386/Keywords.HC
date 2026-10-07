#include "/Compiler/I386/Keywords.HH"
#include "/Compiler/KeywordTable.HC"
#include "/Compiler/I386/SymbolDelete.HH"
#include "/Kernel/I386/Cpu.HH"
//Opcode recognition for the shared HolyC statement parser.
#define I386_INLINE_OPCODES_NUM 40
U8 i386_inline_opcodes[I386_INLINE_OPCODES_NUM][8]={
  {67,76,73,0,0,0,0,0},
  {83,84,73,0,0,0,0,0},
  {72,76,84,0,0,0,0,0},
  {67,76,68,0,0,0,0,0},
  {83,84,68,0,0,0,0,0},
  {78,79,80,0,0,0,0,0},
  {73,78,84,51,0,0,0,0},
  {66,80,84,0,0,0,0,0},
  {67,76,67,0,0,0,0,0},
  {83,84,67,0,0,0,0,0},
  {80,85,83,72,70,68,0,0},
  {80,79,80,70,68,0,0,0},
  {80,85,83,72,65,68,0,0},
  {80,79,80,65,68,0,0,0},
  {77,79,86,0,0,0,0,0},
  {88,79,82,0,0,0,0,0},
  {79,82,0,0,0,0,0,0},
  {67,77,80,0,0,0,0,0},
  {84,69,83,84,0,0,0,0},
  {65,68,68,0,0,0,0,0},
  {83,85,66,0,0,0,0,0},
  {76,69,65,0,0,0,0,0},
  {83,72,76,0,0,0,0,0},
  {65,78,68,0,0,0,0,0},
  {77,79,86,90,88,0,0,0},
  {80,85,83,72,0,0,0,0},
  {80,79,80,0,0,0,0,0},
  {76,71,68,84,0,0,0,0},
  {83,71,68,84,0,0,0,0},
  {76,73,68,84,0,0,0,0},
  {83,73,68,84,0,0,0,0},
  {74,77,80,0,0,0,0,0},
  {74,66,0,0,0,0,0,0},
  {74,78,90,0,0,0,0,0},
  {74,78,69,0,0,0,0,0},
  {74,69,0,0,0,0,0,0},
  {74,90,0,0,0,0,0,0},
  {74,65,0,0,0,0,0,0},
  {74,76,0,0,0,0,0,0},
  {74,71,0,0,0,0,0,0},
};
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
  CHashGeneric *entry; CCompilerKeyword *descriptor; I64 i,j,length,size; U8 *name; U32 flags;
  if(!registry || registry->table || registry->heap) return FALSE;
  registry->table=I386HashTableNew(heap,64);
  if(!registry->table) return FALSE;
  registry->heap=heap;
  for(i=0;i<COMPILER_KEYWORDS_NUM+I386_INLINE_OPCODES_NUM;i++) {
    descriptor=0;
    if(i<COMPILER_KEYWORDS_NUM) { descriptor=compiler_keywords+i; name=descriptor->name; }
    else name=i386_inline_opcodes[i-COMPILER_KEYWORDS_NUM];
    length=0;
    while(name[length]) length++;
    flags=I386IrqSave;
    if(descriptor) size=sizeof(CHashGeneric); else size=sizeof(CHashOpcode);
    entry=I386HeapAlloc(heap,size,TRUE);
    if(entry) {
      entry->str=I386HeapAlloc(heap,length+1,FALSE);
      if(!entry->str) { I386HeapFree(heap,entry); entry=0; }
    }
    I386IrqRestore(flags);
    if(!entry) { I386KeywordsDelete(registry); return FALSE; }
    for(j=0;j<=length;j++) entry->str[j]=name[j];
    if(descriptor) { entry->type=descriptor->type; entry->user_data0=descriptor->value; }
    else entry->type=HTT_OPCODE;
    HashAdd(entry,registry->table);
  }
  return TRUE;
}
