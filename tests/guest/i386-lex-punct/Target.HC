#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/LexPunct.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Bool.HH"
#include "/Kernel/CharBitmaps.HC"
CI386Heap punct_heap;
U32 punct_first[TK_TKS_NUM],punct_second[TK_TKS_NUM],punct_third[TK_TKS_NUM];
CLexPunctTables punct_tables;
extern I64 PunctTest();
extern I64 PunctFailureTest();
extern I64 NativePunctTest();
I64 Main(I64 unused,I64 unused2)
{
  I64 result;
  if(!I386HeapInit(&punct_heap,0x40000,65536)) return 1;
  LexPunctInit(punct_first,punct_second,punct_third);
  punct_tables.first=punct_first; punct_tables.second=punct_second; punct_tables.third=punct_third;
  result=PunctTest; if(result) return result;
  result=PunctFailureTest; if(result) return result;
  result=NativePunctTest; if(result) return result;
  if(punct_heap.used || punct_heap.allocations || !I386HeapValid(&punct_heap)) return 2;
  return 0;
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/LexFiles.HC"
#include "/Compiler/I386/LexInput.HC"
#include "/Compiler/LexPunctInit.HC"
#include "/Compiler/I386/LexPunct.HC"
I64 PunctToken(CCmpCtrl *cc,I64 *lines)
{//Fixture dispatches punctuation only; this is not a general native lexer.
  I64 ch,result;
  do {
    ch=I386LexRawChar(&punct_heap,cc,lines);
    if(ch<0) return -1;
    if(!ch) return cc->token=TK_EOF;
    result=I386LexPunct(&punct_heap,cc,ch,&punct_tables,lines);
  } while(result==-2);
  return result;
}
#include "T:/Cases.HC"
#include "T:/Failures.HC"
#include "T:/Native.HC"
