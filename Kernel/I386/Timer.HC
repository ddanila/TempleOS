#include "/Kernel/I386/Timer.HH"
public Bool I386TimerInit(CI386Timer *timer,I64 divisor)
{
  if(!timer || timer->ready || (GetRFlags&0x200) || divisor<2 || divisor>65536) return 0;
  if(!I386PitStart(divisor)) return 0;
  timer->ticks=0; timer->divisor=divisor; timer->ready=1;
  return 1;
}
public Bool I386TimerStep(CI386Timer *timer)
{
  if(!timer || !timer->ready || (GetRFlags&0x200)) return 0;
  timer->ticks++;
  return 1;
}
public U64 I386TimerTicks(CI386Timer *timer)
{
  U32 flags=I386IrqSave;
  U64 result=0;
  if(timer && timer->ready) result=timer->ticks;
  I386IrqRestore(flags);
  return result;
}
