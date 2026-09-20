#ifndef I386_TIMER_INCLUDED
#define I386_TIMER_INCLUDED
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/PicPit.HH"
#include "/Kernel/TimeTypes.HH"
#define I386_PIT_FREQUENCY 1193182
class CI386Timer
{
  U64 ticks;
  U32 divisor,ready;
  I64 *jiffies;
  U32 jiffy_step,jiffy_fraction,jiffy_remainder;
};
//Caller exclusively owns PIT channel 0; configure with IF clear before unmasking.
//Optional distinct persistent counter uses JIFFY_FREQ units; initialized to zero.
public extern Bool I386TimerInit(CI386Timer *timer,I64 divisor,I64 *jiffies=0);
//Call once per accepted IRQ0 with IF clear. Caller owns EOI; never yields.
public extern Bool I386TimerStep(CI386Timer *timer);
//Atomic single-CPU snapshot, preserving IF. Counts delivered IRQs, modulo 2^64.
public extern U64 I386TimerTicks(CI386Timer *timer);
#endif
