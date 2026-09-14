#ifndef I386_INTERRUPT_INCLUDED
#define I386_INTERRUPT_INCLUDED
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Idt.HH"
#include "/Kernel/I386/Irq.HH"
#include "/Kernel/I386/Exception.HH"
class CI386InterruptServices
{
  U0 (*irq)(CI386IrqFrame *frame);
  U0 (*exception)(CI386ExceptionFrame *frame);
};
//Install once, with IF clear and a live 48..256 gate table. CS=8, DS/ES=16.
public extern Bool I386InterruptInstall(U8 *table,I64 count,U8 *fallback,CI386InterruptServices *services);
public extern U0 I386IrqDispatch(CI386IrqFrame *frame);
public extern U0 I386ExceptionDispatch(CI386ExceptionFrame *frame);
#endif
