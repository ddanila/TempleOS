U0 SleepUntil(I64 wake_jiffy)
{//Not for power-saving.  It is to make a program pause without hogging the CPU.
  Bool old_idle=LBts(&Fs->task_flags,TASKf_IDLE);
  Fs->wake_jiffy=wake_jiffy;
  Yield;
  LBEqu(&Fs->task_flags,TASKf_IDLE,old_idle);
}

U0 Sleep(I64 mS)
{//Not for power-saving.  It is to make a program pause without hogging the CPU.
  if (!mS)
    Yield;
  else
    SleepUntil(cnts.jiffies+mS*JIFFY_FREQ/1000);
}

