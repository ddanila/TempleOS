U8 *it_entry,it_saved[5],*it_string,*it_expected;
Bool it_format,it_args,it_text;
U0 ITRestore(){I64 i;for(i=0;i<5;i++)it_entry[i]=it_saved[i];}
U0 ITHook(U8 *fmt,...)
{
  it_format=StrCmp(fmt,"\"%%s\",%d;Free(%d);")==0;
  it_args=argc==2&&argv[0]==argv[1];
  if(argc==2){it_string=argv[0];it_text=StrCmp(it_string,it_expected)==0;}
}
I64 ITCycle(Bool empty)
{
  I64 i,delta,mask=0,flags=GetRFlags,base,root_base;
  SetRFlags(flags&~512);
  it_entry=&InStr;for(i=0;i<5;i++)it_saved[i]=it_entry[i];
  delta=(&ITHook+0)(I64)-(it_entry+0)(I64)-5;
  if(delta<-0x80000000||delta>0x7FFFFFFF){SetRFlags(flags);return 0;}
  it_string=NULL;it_format=it_args=it_text=FALSE;
  if(empty)it_expected="";else it_expected="A\"B\\C%:42";
  base=Fs->data_heap->used_u8s;root_base=adam_task->data_heap->used_u8s;
  it_entry[0]=0xE9;(it_entry+1)(I32 *)[0]=delta;
  try {if(empty)In("%s","");else In("%s:%d","A\"B\\C%",42);}
  catch {ITRestore;Free(it_string);SetRFlags(flags);}
  ITRestore;
  if(it_format)mask|=1;if(it_args)mask|=2;if(it_text)mask|=4;
  if(it_string&&adam_task->data_heap->used_u8s==root_base+MSize2(it_string))mask|=8;
  Free(it_string);it_string=NULL;
  for(i=0;i<5;i++)if(it_entry[i]!=it_saved[i])break;
  if(i==5)mask|=16;
  if(Fs->data_heap->used_u8s==base&&adam_task->data_heap->used_u8s==root_base)mask|=32;
  SetRFlags(flags);return mask;
}
I64 ITContract(){I64 i,mask=63;for(i=0;i<10;i++){mask&=ITCycle(FALSE);mask&=ITCycle(TRUE);}return mask;}
