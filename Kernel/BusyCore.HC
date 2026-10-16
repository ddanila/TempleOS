U0 Busy(I64 ÊS)
{//Loosely timed.
  I64 i;
  if (cnts.HPET_freq) {
    i=HPET+cnts.HPET_freq*ÊS/1000000;
    while (HPET<i);
  } else
    for (i=0;i<ÊS;i++)
      PortNop;
}
