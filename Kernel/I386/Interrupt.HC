//Native entry modules resolve these imports through the ordinary module linker.
import U0 i386_irq_0();
import U0 i386_irq_1();
import U0 i386_irq_2();
import U0 i386_irq_3();
import U0 i386_irq_4();
import U0 i386_irq_5();
import U0 i386_irq_6();
import U0 i386_irq_7();
import U0 i386_irq_8();
import U0 i386_irq_9();
import U0 i386_irq_10();
import U0 i386_irq_11();
import U0 i386_irq_12();
import U0 i386_irq_13();
import U0 i386_irq_14();
import U0 i386_irq_15();
import U0 i386_exception_0();
import U0 i386_exception_1();
import U0 i386_exception_2();
import U0 i386_exception_3();
import U0 i386_exception_4();
import U0 i386_exception_5();
import U0 i386_exception_6();
import U0 i386_exception_7();
import U0 i386_exception_8();
import U0 i386_exception_9();
import U0 i386_exception_10();
import U0 i386_exception_11();
import U0 i386_exception_12();
import U0 i386_exception_13();
import U0 i386_exception_14();
import U0 i386_exception_15();
import U0 i386_exception_16();
CI386InterruptServices i386_interrupt_services;
Bool i386_interrupt_ready;
U0 I386InterruptStop()
{
  asm { CLI }
  while(1) { asm { HLT } }
}
public U0 I386IrqDispatch(CI386IrqFrame *frame)
{//The installed service owns PIC acceptance/EOI and must not enable IF or yield.
  if(!i386_interrupt_ready || !frame || frame->irq>=16) I386InterruptStop;
  (*i386_interrupt_services.irq)(frame);
}
public U0 I386ExceptionDispatch(CI386ExceptionFrame *frame)
{//Same-ring normalized CPU frame. The service must not enable IF or yield.
  if(!i386_interrupt_ready || !frame || frame->vector>=17) I386InterruptStop;
  (*i386_interrupt_services.exception)(frame);
}
public Bool I386InterruptInstall(U8 *table,I64 count,U8 *fallback,CI386InterruptServices *services)
{
  U8 *entries[33];
  I64 i;
  if(i386_interrupt_ready || (GetRFlags&0x200) || !table || count<48 || count>256 ||
      (table+0)(U64)+count*8>0x100000000 || !fallback || !services ||
      !services->irq || !services->exception) return 0;
  entries[0]=&i386_exception_0;
  entries[1]=&i386_exception_1;
  entries[2]=&i386_exception_2;
  entries[3]=&i386_exception_3;
  entries[4]=&i386_exception_4;
  entries[5]=&i386_exception_5;
  entries[6]=&i386_exception_6;
  entries[7]=&i386_exception_7;
  entries[8]=&i386_exception_8;
  entries[9]=&i386_exception_9;
  entries[10]=&i386_exception_10;
  entries[11]=&i386_exception_11;
  entries[12]=&i386_exception_12;
  entries[13]=&i386_exception_13;
  entries[14]=&i386_exception_14;
  entries[15]=&i386_exception_15;
  entries[16]=&i386_exception_16;
  entries[17]=&i386_irq_0;
  entries[18]=&i386_irq_1;
  entries[19]=&i386_irq_2;
  entries[20]=&i386_irq_3;
  entries[21]=&i386_irq_4;
  entries[22]=&i386_irq_5;
  entries[23]=&i386_irq_6;
  entries[24]=&i386_irq_7;
  entries[25]=&i386_irq_8;
  entries[26]=&i386_irq_9;
  entries[27]=&i386_irq_10;
  entries[28]=&i386_irq_11;
  entries[29]=&i386_irq_12;
  entries[30]=&i386_irq_13;
  entries[31]=&i386_irq_14;
  entries[32]=&i386_irq_15;
  if(!I386IdtInit(table,count,fallback,8)) return 0;
  for(i=0;i<17;i++) I386IdtSet(table,count,i,entries[i],8);
  for(i=0;i<16;i++) I386IdtSet(table,count,i+32,entries[i+17],8);
  i386_interrupt_services.irq=services->irq;
  i386_interrupt_services.exception=services->exception;
  i386_interrupt_ready=1;
  return I386IdtLoad(table,count);
}
