#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/LexString.HH"
#include "/Compiler/I386/LexChar.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/CharBitmaps.HC"
CI386Heap string_heap;
extern I64 StringTest();
extern I64 StringTokenTest();
extern I64 NativeStringTokenTest();
extern I64 CharTest();
extern I64 CharFailureTest();
extern I64 StringFailureTest();
extern I64 NativeStringTest();
extern I64 NativeCharTest();
I64 Main(I64 unused,I64 unused2)
{
  I64 result;
  if(!I386HeapInit(&string_heap,0x40000,65536)) return 1;
  result=StringTokenTest; if(result) return result;
  result=NativeStringTokenTest; if(result) return result;
  result=CharTest; if(result) return result;
  result=CharFailureTest; if(result) return result;
  result=StringTest; if(result) return result;
  result=StringFailureTest; if(result) return result;
  result=NativeCharTest; if(result) return result;
  result=NativeStringTest; if(result) return result;
  if(string_heap.used || string_heap.allocations || !I386HeapValid(&string_heap)) return 2;
  return 0;
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/LexFiles.HC"
#include "/Compiler/I386/LexInput.HC"
#include "/Compiler/I386/LexString.HC"
#include "/Compiler/I386/LexChar.HC"
I64 StringChunk(CCmpCtrl *cc,U8 *buf,I64 size,Bool *done,I64 *lines)
{
  return I386LexStringChunk(&string_heap,cc,buf,size,done,lines);
}
#include "T:/Strings.HC"
I64 CharToken(CCmpCtrl *cc,I64 *lines)
{
  if(I386LexRawChar(&string_heap,cc,lines)!=39) return -1;
  return I386LexChar(&string_heap,cc,lines);
}
#include "T:/CharTests.HC"
#include "T:/Failures.HC"
#include "T:/CharFailures.HC"
#include "T:/Native.HC"

I64 FullString(CCmpCtrl *cc,I64 *lines)
{
  if(I386LexRawChar(&string_heap,cc,lines)!=34) return -1;
  return I386LexStringToken(&string_heap,cc,lines);
}
Bool FullStringFree(CCmpCtrl *cc)
{
  if(I386HeapSize(&string_heap,cc->cur_str)!=cc->cur_str_len || !I386HeapFree(&string_heap,cc->cur_str)) return FALSE;
  cc->cur_str=0; return TRUE;
}
#include "T:/Tokens.HC"
#include "T:/TokenFailures.HC"
