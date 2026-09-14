#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/LexString.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/CharBitmaps.HC"
CI386Heap string_heap;
extern I64 StringTest();
extern I64 StringFailureTest();
extern I64 NativeStringTest();
I64 Main(I64 unused,I64 unused2)
{
  I64 result;
  if(!I386HeapInit(&string_heap,0x40000,65536)) return 1;
  result=StringTest; if(result) return result;
  result=StringFailureTest; if(result) return result;
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
I64 StringChunk(CCmpCtrl *cc,U8 *buf,I64 size,Bool *done,I64 *lines)
{
  return I386LexStringChunk(&string_heap,cc,buf,size,done,lines);
}
#include "T:/Strings.HC"
#include "T:/Failures.HC"
#include "T:/Native.HC"
