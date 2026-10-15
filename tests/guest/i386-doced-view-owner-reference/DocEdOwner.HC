Bool do_entered,do_returned;
U0 DOHold(U8 *data){while(TRUE)Yield;}
U8 *DOHoldTag(CDoc *d,CDocEntry *e,CTask *mem)
{
  if(Fs==d->win_task)do_entered=TRUE;
  return StrNew("Borrow",mem);
}
U0 DOEditor(U8 *data)
{DocEd(data(CDoc *),DOF_DONT_SHOW|DOF_DONT_WINMGR_SYNC);do_returned=TRUE;}
I64 DOContract()
{
  CTask *owner,*editor;
  CDoc *d,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry *e;
  I64 m=0;
  do_entered=do_returned=FALSE;
  owner=Spawn(&DOHold,NULL,"Doc owner",-1,Fs);
  LBtr(&owner->display_flags,DISPLAYf_SHOW);
  d=DocNew("Borrow.DD",owner);
  e=DocPrint(d,"$$TX+TC,\"Borrow\"$$");e->tag_cb=&DOHoldTag;
  //Siblings: normal descendant retirement cannot account for editor exit.
  editor=Spawn(&DOEditor,d,"Doc borrower",-1,Fs);
  LBtr(&editor->display_flags,DISPLAYf_SHOW);
  while(TaskValidate(editor)&&(editor->display_doc!=d||!editor->border_doc))Yield;
  if(do_entered&&TaskValidate(editor)&&editor->display_doc==d)m|=1;
  Kill(owner,TRUE,FALSE);
  if(!TaskValidate(owner))m|=2;
  if(!TaskValidate(editor)&&!do_returned)m|=4;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=8;
  //A failing original keeps the borrower waiting in View. Never
  //resume it onto the retired document; the isolated reference guest ends.
  return m;
}
