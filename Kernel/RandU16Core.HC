U16 RandU16()
{//Random U16.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res.u16[0];
}

