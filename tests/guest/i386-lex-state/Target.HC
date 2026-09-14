#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/LexState.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/Bits.HH"
#include "/Kernel/CharBitmaps.HC"
extern I64 CharBitmapsTest();
extern I64 BitIntrinsicsTest();
extern I64 NativeBitIntrinsicsTest();
CI386Heap state_heap;
I64 state_free_errors;
extern I64 LexStateTest();
extern I64 NativeStateTest();
extern I64 LexFilesTest();
extern I64 NativeFilesTest();
extern I64 LexRawInputTest();
extern I64 NativeInputTest();
extern I64 NativeTakeTest();
extern I64 NativeControlTest();
I64 Main(I64 unused,I64 unused2)
{
  I64 result;
  if(!I386HeapInit(&state_heap,0x40000,65536)) return 8;
  result=NativeBitIntrinsicsTest;
  if(result) return result;
  result=BitIntrinsicsTest;
  if(result) return result;
  result=CharBitmapsTest;
  if(result) return result;
  result=LexRawInputTest;
  if(result) return result;
  result=LexFilesTest;
  if(result) return result;
  result=LexStateTest;
  if(result) return result;
  if(state_free_errors || state_heap.used || state_heap.allocations || !I386HeapValid(&state_heap)) return 9;
  result=NativeStateTest;
  if(result) return result;
  result=NativeFilesTest;
  if(result) return result;
  result=NativeInputTest;
  if(result) return result;
  result=NativeTakeTest;
  if(result) return result;
  return NativeControlTest;
}
#include "T:/NativeBits.HC"
#include "T:/BitIntrinsics.HC"
#include "T:/Bitmaps.HC"
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/LexState.HC"
U8 *StateAlloc(I64 size) { return I386HeapAlloc(&state_heap,size,TRUE); }
U0 StateFree(U8 *allocation) { if(!I386HeapFree(&state_heap,allocation)) state_free_errors++; }
Bool StatePush(CCmpCtrl *cc) { return I386LexPush(&state_heap,cc); }
Bool StatePop(CCmpCtrl *cc,Bool restore) { return I386LexPop(&state_heap,cc,restore); }
#include "T:/State.HC"
I64 NativeStateTest()
{
  CCmpCtrl cc,other;
  CLexFile files[2],*saved;
  CI386Heap small,foreign;
  U8 *bytes;
  I64 i,size,used;
  U32 flags=I386IrqSave;
  bytes=&cc; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=&other; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=files; for(i=0;i<sizeof(CLexFile)*2;i++) bytes[i]=0;
  OutU8(0x21,255); OutU8(0xA1,255);
  CmpCtrlSeed(&cc,CCF_USE_LAST_U16,0,0); cc.lex_include_stk=files;
  cc.last_U16='Q'; cc.cur_buf_ptr=0x12345678; files[0].buf_ptr=0xABCD;
  if(!I386HeapInit(&foreign,0x52000,512)) return 10;
  if(I386LexPush(&state_heap,0) || I386LexPush(&state_heap,&other) ||
      I386LexPush(0,&cc) || I386LexPop(&state_heap,0) || I386LexPop(&state_heap,&cc)) return 11;
  for(size=24;size<88;size+=8) {
    if(!I386HeapInit(&small,0x51000,size) || I386LexPush(&small,&cc) ||
        small.used || small.allocations || cc.lex_prs_stk || cc.flags!=CCF_USE_LAST_U16 ||
        cc.last_U16!='Q' || cc.cur_buf_ptr!=0x12345678 || files[0].buf_ptr!=0xABCD) return 12;
  }
  SetRFlags(GetRFlags|0x200);
  if(!I386LexPush(&state_heap,&cc) || !(GetRFlags&0x200)) return 13;
  saved=cc.lex_prs_stk; used=state_heap.used;
  other.lex_prs_stk=saved; other.lex_include_stk=files;
  if(I386LexPop(&foreign,&cc) || I386LexPop(&state_heap,&other) ||
      cc.lex_prs_stk!=saved || other.lex_prs_stk!=saved || state_heap.used!=used) return 14;
  other.lex_prs_stk=0;
  cc.lex_include_stk=files+1; cc.cur_buf_ptr=0xFEDCBA98;
  if(I386LexPop(&state_heap,&cc) || cc.lex_prs_stk!=saved || cc.cur_buf_ptr!=0xFEDCBA98) return 15;
  //Discard remains legal after changing active files; it never touches their payloads.
  if(!I386LexPop(&state_heap,&cc,FALSE) || !(GetRFlags&0x200) || cc.lex_prs_stk ||
      cc.cur_buf_ptr!=0xFEDCBA98 || state_heap.used || state_heap.allocations) return 16;
  cc.lex_include_stk=files;
  if(!I386LexPush(&state_heap,&cc)) return 17;
  cc.cur_buf_ptr=0x11111111;
  if(!I386LexPop(&state_heap,&cc) || !(GetRFlags&0x200) || cc.cur_buf_ptr!=0xFEDCBA98 ||
      I386LexPop(&state_heap,&cc) || !(GetRFlags&0x200)) return 18;
  I386IrqSave;
  if(!I386LexPush(&state_heap,&cc) || !I386LexPop(&state_heap,&cc) || GetRFlags&0x200 ||
      state_heap.used || state_heap.allocations || !I386HeapValid(&state_heap)) return 19;
  I386IrqRestore(flags); return 0;
}

#include "/Compiler/I386/LexFiles.HC"
#assert sizeof(CI386LexFile)==64
#include "T:/Files.HC"
#include "T:/NativeFiles.HC"

#include "/Compiler/I386/LexInput.HC"
CLexFile *InputPush(CCmpCtrl *cc) { return I386LexFilePush(&state_heap,cc); }
Bool InputPop(CCmpCtrl *cc) { return I386LexFilePop(&state_heap,cc); }
I64 InputRead(CCmpCtrl *cc,I64 *lines) { return I386LexRawChar(&state_heap,cc,lines); }
#include "T:/Input.HC"
#include "T:/NativeInput.HC"

#include "T:/Take.HC"

#include "T:/Control.HC"
