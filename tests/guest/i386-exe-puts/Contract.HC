I64 EUValue=40;
I64 JRContract()
{
  I64 mask=0,base,i;
  CCmpCtrl *boundary=Fs->last_cc;
  U8 *source=StrNew("EUValue+2;"),*title=StrNew(Fs->task_title);
  I64 title_src=Fs->title_src;
  if(ExePutS(source,"Borrowed.HC")==42 && !StrCmp(source,"EUValue+2;"))mask|=1;
  if(ExePutS("1;7;","Multiple.HC")==7)mask|=2;
  //CCF_JUST_LOAD: compile without executing and return successful-load status.
  if(ExePutS("EUValue=99;","Load.HC",64)==1 && EUValue==40)mask|=4;
  if(Fs->last_cc==boundary)mask|=8;
  if(Fs->title_src==title_src && !StrCmp(Fs->task_title,title))mask|=16;
  base=Fs->data_heap->used_u8s;
  for(i=0;i<10;i++)ExePutS(source,"Borrowed.HC");
  if(Fs->data_heap->used_u8s==base)mask|=32;
  Free(source);Free(title);return mask;
}
