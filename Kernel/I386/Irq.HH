#ifndef I386_IRQ_INCLUDED
#define I386_IRQ_INCLUDED
class CI386IrqFrame
{
  U32 gs,fs,es,ds,edi,esi,ebp,saved_esp,ebx,edx,ecx,eax;
  U32 irq,eip,cs,eflags;
};
#assert sizeof(CI386IrqFrame)==64
#endif
