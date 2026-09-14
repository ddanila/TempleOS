#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/LexIdent.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/CharBitmaps.HC"
CI386Heap ident_heap;
extern I64 IdentTest();
extern I64 IdentLookupTest();
extern I64 IdentFailureTest();
extern I64 NativeIdentTest();
extern I64 NativeIncludeTest();
extern I64 MacroTest();
extern I64 NativeTokenTest();
I64 Main(I64 unused,I64 unused2)
{
  I64 result;
  if(!I386HeapInit(&ident_heap,0x40000,65536)) return 1;
  result=MacroTest; if(result) return result;
  result=NativeTokenTest; if(result) return result;
  result=IdentTest; if(result) return result;
  result=IdentLookupTest; if(result) return result;
  result=IdentFailureTest; if(result) return result;
  result=NativeIncludeTest; if(result) return result;
  result=NativeIdentTest; if(result) return result;
  if(ident_heap.used || ident_heap.allocations || !I386HeapValid(&ident_heap)) return 2;
  return 0;
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Hash.HC"
#include "/Compiler/MemberLookup.HC"
#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/LexFiles.HC"
#include "/Compiler/I386/LexInput.HC"
#include "/Compiler/I386/LexIdent.HC"
I64 IdentToken(CCmpCtrl *cc,U8 *output,I64 *lines)
{
  I64 ch=I386LexRawChar(&ident_heap,cc,lines),token,i;
  token=I386LexIdentToken(&ident_heap,cc,ch,"Macro",lines);
  if(token==TK_IDENT) {
    if(I386HeapSize(&ident_heap,cc->cur_str)!=cc->cur_str_len) return 198;
    for(i=0;i<cc->cur_str_len;i++) output[i]=cc->cur_str[i];
    if(!I386HeapFree(&ident_heap,cc->cur_str)) return 199;
    cc->cur_str=0;
  }
  return token;
}
I64 MacroNext(CCmpCtrl *cc,I64 *lines)
{//Identifier/semicolon fixture dispatch only.
  I64 ch,result;
  do {
    ch=I386LexRawChar(&ident_heap,cc,lines);
    if(!ch) return cc->token=0;
    if(ch==59) {
      cc->token=59;
      if(I386LexRawChar(&ident_heap,cc,lines)<0) return -1;
      cc->flags|=CCF_USE_LAST_U16; return 59;
    }
    result=I386LexIdentToken(&ident_heap,cc,ch,"Macro",lines);
  } while(result==-2);
  return result;
}
Bool MacroTextFree(CCmpCtrl *cc)
{
  if(cc->cur_str && !I386HeapFree(&ident_heap,cc->cur_str)) return FALSE;
  cc->cur_str=0; return TRUE;
}
#include "T:/Cases.HC"
#include "T:/Lookup.HC"
#include "T:/Failures.HC"
#include "T:/Native.HC"
#include "T:/Include.HC"
#include "T:/Macros.HC"
#include "T:/Token.HC"
