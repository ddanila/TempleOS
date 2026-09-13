#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Irq.HH"
extern U0 I386PicInit();
extern U0 I386PicMask(U16 mask);
extern U16 I386PicMaskGet();
extern Bool I386PicAccept(I64 irq);
extern Bool I386PicEoi(I64 irq);
extern Bool I386PitStart(I64 divisor);
extern U16 I386PitRead();
extern U0 OnIrq(CI386IrqFrame *frame);
class CIrqTestControl { U0 (*handler)(CI386IrqFrame *frame); U32 ticks; U32 (*flags)(); };
CIrqTestControl *control;
I64 ticks,spurious,errors;
I64 Main(I64 a,I64 b)
{
  I64 (*wait)(I64 count);
  I64 first,i,result;
  wait=b;
  control=a; control->handler=&OnIrq;
  ticks=0xFFFFFFF0; spurious=0; errors=0;
  I386PicInit;
  if (I386PicMaskGet!=0xFFFF || I386PicAccept(-1) || I386PicAccept(16) ||
      I386PicEoi(-1) || I386PicEoi(16)) return 1;
  if (I386PitStart(0) || I386PitStart(1) || I386PitStart(65537) ||
      !I386PitStart(65536) || !I386PitStart(11932)) return 2;
  first=I386PitRead;
  for (i=0;i<10000;i++) if (I386PitRead!=first) break;
  if (i==10000 || I386PitRead>11932) return 3;
  I386PicMask(0xFFFE);
  if (I386PicMaskGet!=0xFFFE) return 4;
  result=(*wait)(32);
  I386PicMask(0xFFFF);
  if (result || errors || spurious!=2 || control->ticks<32 ||
      ticks!=0xFFFFFFF0+control->ticks || ticks<0x100000000) return 5;
  first=ticks; spurious=0;
  I386PicInit;
  if (!I386PitStart(65536)) return 6;
  I386PicMask(0xFFFE);
  result=(*wait)(4);
  I386PicMask(0xFFFF);
  if (result || errors || spurious!=2 || control->ticks<4 ||
      ticks!=first+control->ticks) return 7;
  return 0;
}
U0 OnIrq(CI386IrqFrame *frame)
{
  if (!I386PicAccept(frame->irq)) { spurious++; return; }
  if (frame->irq!=0 || (frame->cs&65535)!=8 || (frame->eflags&0x600)!=0x600 ||
      (frame->ds&65535)!=16 || (frame->es&65535)!=16 ||
      (frame->fs&65535) || (frame->gs&65535) ||
      frame->saved_esp!=(frame+0)(U64)+48) errors++;
  if (frame->eax!=0x11223344 || frame->ebx!=0x22334455 || frame->ecx!=0x33445566 ||
      frame->edx!=0x44556677 || frame->esi!=0x55667788 || frame->edi!=0x66778899 ||
      frame->ebp!=0x778899AA) errors++;
  if ((*control->flags)()&0x600) errors++;
  ticks++; control->ticks++;
  I386PicEoi(frame->irq);
}
#include "/Kernel/I386/PicPit.HC"
