#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Compiler/I386/Keywords.HH"
#include "/Compiler/I386/SymbolDelete.HH"
#include "/Kernel/I386/Cpu.HH"
CI386Heap keyword_heap;
extern I64 KeywordMapTest(CHashTable *table);
extern I64 KeywordTest();
extern I64 KeywordFailureTest();
I64 Main(I64 unused,I64 unused2)
{
  I64 result;
  if(!I386HeapInit(&keyword_heap,0x40000,65536)) return 1;
  result=KeywordTest; if(result) return result;
  result=KeywordFailureTest; if(result) return result;
  if(keyword_heap.used || keyword_heap.allocations || !I386HeapValid(&keyword_heap)) return 2;
  return 0;
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Hash.HC"
#include "/Kernel/I386/HashTable.HC"
#include "/Compiler/I386/SymbolDelete.HC"
#include "/Compiler/I386/Keywords.HC"
#include "T:/Map.HC"
I64 KeywordTest()
{
  CI386Keywords registry; CHashGeneric *entry,shadow; CHashTable local; CHash *bucket=0;
  I64 i,length,expected=320,result; U8 *bytes;
  registry.heap=0; registry.table=0;
  if(!I386KeywordsInit(&registry,&keyword_heap)) return 3;
  result=KeywordMapTest(registry.table); if(result) return result;
  for(i=0;i<COMPILER_KEYWORDS_NUM;i++) {
    length=0; while(compiler_keywords[i].name[length]) length++;
    expected+=56+16+((length+1+7)&~7);
    entry=HashFind(compiler_keywords[i].name,registry.table,compiler_keywords[i].type);
    if(entry->str==compiler_keywords[i].name || I386HeapSize(&keyword_heap,entry)!=40 ||
        I386HeapSize(&keyword_heap,entry->str)!=length+1 || entry->user_data1 || entry->user_data2) return 4;
  }
  if(keyword_heap.used!=expected || keyword_heap.allocations!=2+COMPILER_KEYWORDS_NUM*2 ||
      I386KeywordsInit(&registry,&keyword_heap) || keyword_heap.used!=expected) return 5;
  bytes=&local; for(i=0;i<sizeof(CHashTable);i++) bytes[i]=0;
  bytes=&shadow; for(i=0;i<sizeof(CHashGeneric);i++) bytes[i]=0;
  local.body=&bucket; local.next=registry.table;
  shadow.str="define"; shadow.type=HTT_GLBL_VAR; HashAdd(&shadow,&local);
  if(HashFind("define",&local,HTG_TYPE_MASK)!=&shadow ||
      HashFind("define",&local,HTT_KEYWORD)==&shadow ||
      HashFind("define",&local,HTT_KEYWORD)!=HashFind("define",registry.table,HTT_KEYWORD)) return 6;
  local.next=0;
  registry.table->locked_flags=1;
  if(I386KeywordsDelete(&registry) || !registry.table || registry.heap!=&keyword_heap || keyword_heap.used!=expected) return 7;
  registry.table->locked_flags=0;
  if(!I386KeywordsDelete(&registry) || registry.heap || registry.table || keyword_heap.used || keyword_heap.allocations ||
      !I386KeywordsDelete(&registry) || !I386KeywordsInit(&registry,&keyword_heap) || !I386KeywordsDelete(&registry)) return 8;
  return 0;
}
I64 KeywordFailureTest()
{
  CI386Heap scratch; CI386Keywords registry;
  I64 size,failed=0,passed=0,result;
  registry.heap=0; registry.table=0;
  for(size=32;size<=8192;size+=8) {
    if(!I386HeapInit(&scratch,0x50000,size)) return 9;
    if(I386KeywordsInit(&registry,&scratch)) {
      passed++; result=KeywordMapTest(registry.table); if(result) return result;
      if(!I386KeywordsDelete(&registry)) return 10;
    } else failed++;
    if(registry.heap || registry.table || scratch.used || scratch.allocations || !I386HeapValid(&scratch)) return 11;
  }
  if(!failed || !passed) return 12;
  return 0;
}
