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
I64 Main(I64 unused,I64 unused2)
{
  I64 result;
  if(!I386HeapInit(&ident_heap,0x40000,65536)) return 1;
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
{//Fixture supplies publication/lookahead for comparison with production Lex.
  I64 ch=I386LexRawChar(&ident_heap,cc,lines),length; CHash *entry;
  length=I386LexIdentScan(&ident_heap,cc,ch,output,144,&entry,lines);
  if(length<0) return length;
  cc->hash_entry=entry; cc->cur_str_len=length; cc->token=TK_IDENT;
  if(I386LexRawChar(&ident_heap,cc,lines)<0) return -1;
  cc->flags|=CCF_USE_LAST_U16;
  return TK_IDENT;
}
#include "T:/Cases.HC"
#include "T:/Lookup.HC"
#include "T:/Failures.HC"
#include "T:/Native.HC"
#include "T:/Include.HC"
