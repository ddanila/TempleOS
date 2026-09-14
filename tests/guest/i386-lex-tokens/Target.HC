#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/Lex.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/CharBitmaps.HC"
CI386Heap token_heap;
U32 token_first[TK_TKS_NUM],token_second[TK_TKS_NUM],token_third[TK_TKS_NUM];
CLexPunctTables token_tables;
extern I64 StreamTest();
extern I64 ModeTest();
extern I64 MacroTest();
extern I64 NativeTest();
extern I64 DefineTest();
extern I64 DefineNativeTest();
extern I64 DefineFailures();
I64 Main(I64 unused,I64 unused2)
{
  I64 result;
  if(!I386HeapInit(&token_heap,0x60000,65536)) return 1;
  LexPunctInit(token_first,token_second,token_third);
  token_tables.first=token_first; token_tables.second=token_second; token_tables.third=token_third;
  result=DefineTest; if(result) return result;
  result=DefineNativeTest; if(result) return result;
  result=DefineFailures; if(result) return result;
  result=StreamTest; if(result) return result;
  result=ModeTest; if(result) return result;
  result=MacroTest; if(result) return result;
  result=NativeTest; if(result) return result;
  if(token_heap.used || token_heap.allocations || !I386HeapValid(&token_heap)) return 2;
  return 0;
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Hash.HC"
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
I64 MacroNext(CCmpCtrl *cc,I64 *lines) { return I386LexNext(&token_heap,cc,&token_tables,"Macro",lines); }
Bool MacroTextFree(CCmpCtrl *cc)
{
  if(cc->cur_str && (I386HeapSize(&token_heap,cc->cur_str)!=cc->cur_str_len || !I386HeapFree(&token_heap,cc->cur_str))) return FALSE;
  cc->cur_str=0; return TRUE;
}
#include "T:/Streams.HC"
#include "T:/Macros.HC"
#include "T:/Native.HC"
#include "T:/DefineNative.HC"
#include "T:/Defines.HC"
#include "T:/DefineFailures.HC"
