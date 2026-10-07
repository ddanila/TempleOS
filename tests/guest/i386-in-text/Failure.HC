U8 *it_entry,it_saved[5];Bool it_args,it_format;
U0 ITRestore(){I64 i;for(i=0;i<5;i++)it_entry[i]=it_saved[i];}
U0 ITHook(U8 *fmt,...)
{
  it_args=argc==2&&argv[0]==argv[1];
  it_format=StrCmp(fmt,"\"%%s\",%d;Free(%d);")==0;
  throw('Break',TRUE);
}
I64 ITContract()
{
  I64 i,delta,mask=0,flags=GetRFlags,base,root_base;
  Bool caught=FALSE;
  SetRFlags(flags&~512);
  it_entry=&InStr;for(i=0;i<5;i++)it_saved[i]=it_entry[i];
  delta=(&ITHook+0)(I64)-(it_entry+0)(I64)-5;
  if(delta<-0x80000000||delta>0x7FFFFFFF){SetRFlags(flags);return 0;}
  it_args=it_format=FALSE;
  base=Fs->data_heap->used_u8s;root_base=adam_task->data_heap->used_u8s;
  it_entry[0]=0xE9;(it_entry+1)(I32 *)[0]=delta;
  try {In("%s","Reject");}
  catch {ITRestore;caught=Fs->except_ch=='Break';Fs->catch_except=TRUE;}
  ITRestore;
  for(i=0;i<5;i++)if(it_entry[i]!=it_saved[i])break;
  if(i==5)mask|=1;if(caught)mask|=2;
  if(it_args)mask|=4;if(it_format)mask|=8;
  if(Fs->data_heap->used_u8s==base)mask|=16;
  if(adam_task->data_heap->used_u8s==root_base)mask|=32;
  SetRFlags(flags);return mask;
}
