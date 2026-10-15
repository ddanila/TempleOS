Bool de_armed;
U8 *DEFailTag(CDoc *d,CDocEntry *e,CTask *mem)
{if(de_armed&&Fs==d->win_task){de_armed=FALSE;throw('DEFail',TRUE);}return StrNew("Fault",mem);}
I64 DEFailure(Bool locked)
{
  CDoc *d=DocNew("Failure.DD"),*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry *e=DocPrint(d,"$$TX+TC,\"Fault\"$$");
  I64 attr=Fs->text_attr,src=Fs->title_src,before,m=0;
  U8 *title=StrNew(Fs->task_title);
  Bool caught=FALSE;
  e->tag_cb=&DEFailTag;
  if(locked)DocLock(d);
  before=Fs->data_heap->used_u8s;de_armed=TRUE;
  try{DocEd(d,DOF_DONT_SHOW|DOF_DONT_WINMGR_SYNC);}
  catch{caught=Fs->except_ch=='DEFail';Fs->catch_except=TRUE;}
  de_armed=FALSE;
  if(caught)m|=1;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=2;
  if(Fs->text_attr==attr&&Fs->title_src==src&&!StrCmp(Fs->task_title,title))m|=4;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==locked)m|=8;
  if(Fs->data_heap->used_u8s==before)m|=16;
  DocUnlock(d);DocDel(d);Free(title);return m;
}
