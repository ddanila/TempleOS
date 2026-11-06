#include "C:/Probe/NativeCallArgs.HC"
I64 ICTarget0(){return 0x1234567887654321;}
I64 ICTarget1(I64 a){return a^0x13579BDF2468ACE0;}
I64 ICTarget3(I64 a,I64 b,I64 c){return a+3*b+5*c;}
I64 ICScales(U8 *base,I64 index)
{
  U32 result;
  asm {
    PUSH ESI
    MOV ESI,U32 &base[EBP]
    MOV ECX,U32 &index[EBP]
    MOV EAX,U32 [ESI+ECX*1]
    ADD EAX,U32 [ESI+ECX*2]
    ADD EAX,U32 [ESI+ECX*4]
    ADD EAX,U32 [ESI+ECX*8]
    MOV U32 &result[EBP],EAX
    POP ESI
  }
  return result;
}
I64 ICDecFlags()
{
  U32 value=1,reg_flags,mem_flags;
  asm {
    STC
    MOV EAX,1
    DEC EAX
    PUSHFD
    POP EDX
    AND EDX,0x41
    MOV U32 &reg_flags[EBP],EDX
    STC
    DEC U32 &value[EBP]
    PUSHFD
    POP EDX
    AND EDX,0x41
    MOV U32 &mem_flags[EBP],EDX
  }
  return value==0 && reg_flags==0x41 && mem_flags==0x41;
}
I64 ICMemoryCall(U8 **address)
{
  I64 result;
  asm {
    MOV ECX,U32 &address[EBP]
    CALL U32 [ECX]
    MOV U32 &result[EBP],EAX
    MOV U32 &result+4[EBP],EDX
  }
  return result;
}
U0 ICLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 InlineCallCheck()
{
  I64 args[3],mask=0,i;
  U8 bytes[64];U8 *address=&ICTarget0;
  args[0]=0x102030405060708;args[1]=-0x1122334455;args[2]=0x55667788;
  if(NativeCallArgs(&ICTarget0,0,args)==0x1234567887654321)mask|=1;
  if(NativeCallArgs(&ICTarget1,1,args)==(args[0]^0x13579BDF2468ACE0))mask|=2;
  if(NativeCallArgs(&ICTarget3,3,args)==args[0]+3*args[1]+5*args[2])mask|=4;
  for(i=0;i<64;i++)bytes[i]=i;
  if(ICScales(bytes,1)==0x1B17130F)mask|=8;
  if(ICDecFlags)mask|=16;
  if(ICMemoryCall(&address)==0x1234567887654321)mask|=32;
  ICLog(MStrPrint("EXPORT call-code.bin %X 100\n",&NativeCallArgs));
  ICLog(MStrPrint("EXPORT scales-code.bin %X 100\n",&ICScales));
  ICLog(MStrPrint("INLINE CALL MASK %d\n",mask));
  if(mask!=63)throw('InlCall',TRUE);
}
