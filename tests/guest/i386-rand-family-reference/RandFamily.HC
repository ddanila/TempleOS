#define RF_WORDS 64
I64 *RFCollect()
{
  I64 *values=CAlloc(RF_WORDS*8),seeds[4];
  I64 saved_seed=Fs->rand_seed,saved_flags=Fs->task_flags,i,j,k=0,value;
  F64 real;
  seeds[0]=0;seeds[1]=1;seeds[2]=0x123456789ABCDEF0;seeds[3]=0xFFFFFFFFFFFFFFFF;
  for(i=0;i<4;i++) {
    for(j=0;j<7;j++) {
      Fs->rand_seed=seeds[i];Bts(&Fs->task_flags,TASKf_NONTIMER_RAND);
      switch(j) {
        case 0:value=RandI16;break;
        case 1:value=RandU16;break;
        case 2:value=RandI32;break;
        case 3:value=RandU32;break;
        case 4:value=RandI64;break;
        case 5:value=RandU64;break;
        case 6:real=Rand;value=(&real)(I64 *)[0];break;
      }
      values[k++]=value;values[k++]=Fs->rand_seed;
    }
  }
  Btr(&Fs->task_flags,TASKf_NONTIMER_RAND);Fs->rand_seed=0;
  values[k++]=Seed(0x1234);values[k++]=Fs->rand_seed;
  values[k++]=Bt(&Fs->task_flags,TASKf_NONTIMER_RAND);
  Fs->rand_seed=saved_seed;Fs->task_flags=saved_flags;
  return values;
}
I64 RFCheck()
{
  I64 size=0,*expected=FileRead("C:/RandFamily.bin",&size),*actual=RFCollect,ok;
  ok=expected&&size==RF_WORDS*8&&!MemCmp(expected,actual,size);
  Free(expected);Free(actual);return ok;
}
