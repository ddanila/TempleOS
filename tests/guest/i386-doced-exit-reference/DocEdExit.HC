Bool dx_entered,dx_returned,dx_armed;
U8 *DXExitTag(CDoc *d,CDocEntry *e,CTask *mem)
{
  if(dx_armed&&Fs==d->win_task){dx_entered=TRUE;dx_armed=FALSE;Exit;}
  return StrNew("Exit",mem);
}
U0 DXWorker(U8 *data)
{DocEd(data(CDoc *),DOF_DONT_SHOW|DOF_DONT_WINMGR_SYNC);dx_returned=TRUE;}
I64 DXContract()
{
  CDoc *d=DocNew("Exit.DD"),*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry *e=DocPrint(d,"$$TX+TC,\"Exit\"$$");
  CTask *child;
  I64 m=0,before;
  e->tag_cb=&DXExitTag;dx_entered=dx_returned=FALSE;dx_armed=TRUE;
  child=Spawn(&DXWorker,d,"DocEd Exit",-1,Fs);
  while(TaskValidate(child))Yield;
  dx_armed=FALSE;
  if(dx_entered)m|=1;
  if(!dx_returned)m|=2;
  if(!Bt(&d->locked_flags,DOClf_LOCKED))m|=4;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=8;
  if(d->win_task==Fs)m|=32;
  //After recording the lock state, let the failed original control continue.
  d->owning_task=NULL;LBtr(&d->locked_flags,DOClf_LOCKED);d->win_task=Fs;
  before=DocSize(d);DocPrint(d,"Continued\n");
  if(DocSize(d)>before)m|=16;
  DocDel(d);return m;
}
