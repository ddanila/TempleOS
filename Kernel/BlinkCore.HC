#ifndef BLINK_JIFFIES
#define BLINK_JIFFIES cnts.jiffies
#endif
Bool Blink(F64 Hz=2.5)
{//Return TRUE, then FALSE, then TRUE at given frequency.
  if (!Hz) return 0;
  return ToI64(BLINK_JIFFIES*2*Hz/JIFFY_FREQ)&1;
}

