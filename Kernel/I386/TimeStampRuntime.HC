//PIT units, not CPU cycles. All state is private to the single-CPU console.
#include "/Kernel/I386/ConsolePitRead.HC"
Bool native_stamp_ready;
I64 native_stamp_last_count,native_stamp_last_value;
I64 NativeTimeStamp()
{
  U32 flags=I386IrqSave;
  I64 count=NativeRandPitRead,divisor=console_config->pit_divisor;
  I64 value=*console_config->pit_ticks*divisor+divisor-count,delta;
  if(native_stamp_ready) {
    delta=native_stamp_last_count-count;
    if(delta<0)delta+=divisor;
    if(value<native_stamp_last_value+delta)value=native_stamp_last_value+delta;
  }
  native_stamp_last_count=count; native_stamp_last_value=value;
  native_stamp_ready=TRUE;
  I386IrqRestore(flags);
  return value;
}
U0 NativeTimeStampInit()
{
  CCntsGlbls *counts=console_config->jiffies(CCntsGlbls *);
  counts->time_stamp_freq=1193182;
  counts->time_stamp_kHz_freq=1193;
  counts->time_stamp_freq_initial=1193182;
  counts->time_stamp_calibrated=TRUE; //Known fixed PIT source; no CPU calibration.
  NativeTimeStamp;
}
