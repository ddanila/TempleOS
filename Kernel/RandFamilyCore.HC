I16 RandI16()
{//Random I16.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res.i16[0];
}

#include "/Kernel/RandU16Core.HC"

I32 RandI32()
{//Random I32.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res.i32[0];
}

U32 RandU32()
{//Random U32.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res.u32[0];
}

I64 RandI64()
{//Random I64.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res;
}

U64 RandU64()
{//Random U64.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return res;
}

F64 Rand()
{//Random F64.
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  if (!Bt(&Fs->task_flags,TASKf_NONTIMER_RAND))
    res^=GetTSC;
  Fs->rand_seed=res;
  return (res&0x3FFFFFFFFFFFFFFF)/ToF64(0x4000000000000000);
}

I64 Seed(I64 seed=0,CTask *task=NULL)
{//Set $LK,"Rand",A="MN:Rand"$() seed. Zero for timer-based.
  if (!task) task=Fs;
  if (seed) {
    LBts(&task->task_flags,TASKf_NONTIMER_RAND);
    return task->rand_seed=seed;
  } else {
    LBtr(&task->task_flags,TASKf_NONTIMER_RAND);
    return task->rand_seed^=GetTSC;
  }
}
