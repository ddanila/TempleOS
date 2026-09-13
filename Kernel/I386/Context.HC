#include "/Kernel/I386/Context.HH"
public Bool I386ContextInit(CI386Context *context,U8 *stack,I64 size,
  U0 (*entry)(I64 arg),I64 arg,U0 (*exit)(),U16 fs=16,U16 gs=16)
{//Fresh, exclusively owned stack; entry returns to exit, which must never return.
  U64 begin=(stack+0)(U64),control=(context+0)(U64),end;
  U32 *frame;
  I64 i;
  if (!context || !stack || !entry || !exit || begin&7 || size<256 ||
      size>0xFFFFFFFF || size&7) return FALSE;
  end=begin+size;
  if (end>0xFFFFFFFF || (control<end && control+4>begin)) return FALSE;
  frame=stack+size-88;
  for (i=0;i<22;i++) frame[i]=0;
  frame[0]=gs; frame[1]=fs; frame[2]=16; frame[3]=16;
  frame[12]=2; //EFLAGS: IF/DF clear; reserved bit 1 set.
  frame[13]=entry;
  //Words 14..17 are discarded as the switch's two eight-byte arguments.
  frame[18]=exit; frame[19]=arg; frame[20]=arg>>32;
  context->esp=frame;
  return TRUE;
}
