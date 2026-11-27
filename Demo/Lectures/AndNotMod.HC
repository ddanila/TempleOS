//$WW,1$You may wonder why I use "&" instead of "%".

#define SAMPLE_SIZE	100000000

U0 TimeIns()
{
  I64 start1,end1,start2,end2,overhead_time,test_time;
  I64 reg i,reg tmp;

#ifdef I386_PUBLIC_USER_INCLUDED
  "%03X Cores %d Hz PIT counter\n",mp_cnt,cnts.time_stamp_freq;
#else
  CPURep;
#endif

  //Measure Loop Overhead
  start1=GetTSC;
  for (i=0;i<SAMPLE_SIZE;i++) {
  }
  end1=GetTSC;
  overhead_time=end1-start1;

  //Measure remainder...
  start2=GetTSC;
  for (i=0;i<SAMPLE_SIZE;i++)
    tmp=i%0x400;
  end2=GetTSC;
  test_time=end2-start2;
#ifdef I386_PUBLIC_USER_INCLUDED
  "Remainder Version #1 PIT ticks\t: %10.5f\n",
#else
  "Remainder Version #1 Cycles\t: %10.5f\n",
#endif
	ToF64(test_time-overhead_time)/SAMPLE_SIZE;

  //Measure remainder...
  start2=GetTSC;
  for (i=0;i<SAMPLE_SIZE;i++)
    tmp=i&0x3FF;
  end2=GetTSC;
  test_time=end2-start2;
#ifdef I386_PUBLIC_USER_INCLUDED
  "Remainder Version #2 PIT ticks\t: %10.5f\n",
#else
  "Remainder Version #2 Cycles\t: %10.5f\n",
#endif
	ToF64(test_time-overhead_time)/SAMPLE_SIZE;
}

TimeIns;

/*  Program Output$HL,0$$WW+H,1$$FD,1$
8 Cores 2.660GHz
Remainder Version #1 Cycles	:   26.85345
Remainder Version #2 Cycles	:   -0.00800
$HL,1$*/
