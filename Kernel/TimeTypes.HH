#ifndef TIME_TYPES_INCLUDED
#define TIME_TYPES_INCLUDED
public class CCntsGlbls
{
  I64	jiffies,	//$LK,"JIFFY_FREQ",A="MN:JIFFY_FREQ"$
	timer,		//$LK,"SYS_TIMER_FREQ",A="MN:SYS_TIMER_FREQ"$. Use $LK,"SysTimerRead",A="MN:SysTimerRead"$().
	time_stamp_freq,
	time_stamp_kHz_freq,
	time_stamp_freq_initial, //Initial freq, sampled once at boot time.
	HPET_freq,
	HPET_kHz_freq,
	HPET_initial;	//Initial count, sampled at boot time.
  Bool	time_stamp_calibrated;
};

#define JIFFY_FREQ		1000 // Hz
#define CDATE_FREQ		49710 // Hz
#define SYS_TIMER_FREQ		(18333*65536/1000) //Hz
#define SYS_TIMER0_PERIOD	(65536*182/10/JIFFY_FREQ)

#endif
