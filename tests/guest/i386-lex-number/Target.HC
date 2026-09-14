#include "/Kernel/Types.HH"
#define TRUE 1
#define NATIVE_NUMBER_TEST
#define FALSE 0
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/LexNumber.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/CharBitmaps.HC"
CI386Heap number_heap;
extern I64 NumberTest();
extern I64 NumberFailureTest();
extern I64 NativeNumberTest();
I64 Main(I64 unused,I64 unused2)
{
  I64 result;
  if(!I386HeapInit(&number_heap,0x60000,65536)) return 1;
  result=NumberTest; if(result) return result;
  result=NumberFailureTest; if(result) return result;
  return NativeNumberTest;
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/SoftF64.HC"
#include "/Kernel/I386/Pow10.HC"
#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/LexFiles.HC"
#include "/Compiler/I386/LexInput.HC"
#include "/Compiler/I386/LexNumber.HC"
I64 NumberRead(CCmpCtrl *cc,I64 *lines)
{
  I64 ch;
  cc->last_line_num=cc->lex_include_stk->line_num;
  ch=I386LexRawChar(&number_heap,cc,lines);
  if(ch<0) return -1;
  return I386LexNumber(&number_heap,cc,ch,lines);
}
#include "T:/Numbers.HC"

#include "T:/Failures.HC"
#include "T:/Native.HC"
