#ifndef I386_TIMER_INCLUDED
#define I386_TIMER_INCLUDED
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/PicPit.HH"
class CI386Timer
{
  U64 ticks;
  U32 divisor,ready;
};
//Caller exclusively owns PIT channel 0; configure with IF clear before unmasking.
public extern Bool I386TimerInit(CI386Timer *timer,I64 divisor);
//Call once per accepted IRQ0 with IF clear. Caller owns EOI; never yields.
public extern Bool I386TimerStep(CI386Timer *timer);
//Atomic single-CPU snapshot, preserving IF. Counts delivered IRQs, modulo 2^64.
public extern U64 I386TimerTicks(CI386Timer *timer);
#endif
