#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/Lex.HH"
#include "/Compiler/I386/Keywords.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/CharBitmaps.HC"
CI386Heap token_heap;
U32 token_first[TK_TKS_NUM],token_second[TK_TKS_NUM],token_third[TK_TKS_NUM];
CLexPunctTables token_tables;
CI386Keywords keywords;
extern I64 ConditionalTest();
extern I64 ConditionalEdgeTest();
extern I64 ConditionalFailureTest();
extern I64 NativeConditionalTest();
extern I64 IncludeTest();
extern I64 IncludeFailureTest();
I64 Main(I64 unused,I64 unused2)
{
  I64 result;
  if(!I386HeapInit(&token_heap,0x60000,65536) || !I386KeywordsInit(&keywords,&token_heap)) return 1;
  LexPunctInit(token_first,token_second,token_third);
  token_tables.first=token_first; token_tables.second=token_second; token_tables.third=token_third;
  result=ConditionalTest; if(result) return result;
  result=ConditionalEdgeTest; if(result) return result;
  result=ConditionalFailureTest; if(result) return result;
  result=NativeConditionalTest; if(result) return result;
  result=IncludeTest; if(result) return result;
  result=IncludeFailureTest; if(result) return result;
  if(!I386KeywordsDelete(&keywords) || token_heap.used || token_heap.allocations || !I386HeapValid(&token_heap)) return 2;
  return 0;
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Hash.HC"
#include "/Kernel/I386/HashTable.HC"
#include "/Compiler/MemberLookup.HC"
#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/LexFiles.HC"
#include "/Compiler/I386/LexInput.HC"
#include "/Compiler/I386/LexString.HC"
#include "/Kernel/I386/SoftF64.HC"
#include "/Kernel/I386/Pow10.HC"
#include "/Compiler/I386/LexNumber.HC"
#include "/Compiler/I386/LexChar.HC"
#include "/Compiler/LexPunctInit.HC"
#include "/Compiler/I386/LexPunct.HC"
#include "/Compiler/I386/LexIdent.HC"
#include "/Compiler/I386/Lex.HC"
#include "/Compiler/I386/LexDefine.HC"
#include "/Compiler/I386/SymbolDelete.HC"
#include "/Compiler/I386/Keywords.HC"
CHashTable *ConditionalKeywords() { return keywords.table; }
I64 ConditionalNext(CCmpCtrl *cc,I64 *lines) { return I386LexNext(&token_heap,cc,&token_tables,"Macro",lines); }
Bool ConditionalFree(CCmpCtrl *cc)
{
  if(cc->cur_str && !I386HeapFree(&token_heap,cc->cur_str)) return FALSE;
  cc->cur_str=0; return TRUE;
}
#include "T:/Common.HC"
#include "T:/Cases.HC"
#include "T:/Failures.HC"
#include "T:/Native.HC"

#include "T:/IncludeNative.HC"
