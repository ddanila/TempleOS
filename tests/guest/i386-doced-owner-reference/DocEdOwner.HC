Bool do_entered,do_returned,do_ordered;
CTask *do_owner;
CDoc *do_doc;
U0 DOEnd()
{
  do_ordered=TaskValidate(do_owner)&&MHeapCtrl(do_doc)==do_owner->data_heap&&
    do_doc->doc_signature==DOC_SIGNATURE_VAL;
}
U0 DOHold(U8 *data){while(TRUE)Yield;}
U8 *DOHoldTag(CDoc *d,CDocEntry *e,CTask *mem)
{
  if(Fs==d->win_task){do_entered=TRUE;while(TRUE)Yield;}
  return StrNew("Borrow",mem);
}
U0 DOEditor(U8 *data)
{Fs->task_end_cb=&DOEnd;DocEd(data(CDoc *),DOF_DONT_SHOW|DOF_DONT_WINMGR_SYNC);do_returned=TRUE;}
I64 DOContract()
{
  CTask *owner,*editor;
  CDoc *d,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry *e;
  I64 m=0;
  do_entered=do_returned=do_ordered=FALSE;
  owner=Spawn(&DOHold,NULL,"Doc owner",-1,Fs);
  d=DocNew("Borrow.DD",owner);
  do_owner=owner;do_doc=d;
  e=DocPrint(d,"$$TX+TC,\"Borrow\"$$");e->tag_cb=&DOHoldTag;
  //Siblings: normal descendant retirement cannot account for editor exit.
  editor=Spawn(&DOEditor,d,"Doc borrower",-1,Fs);
  while(!do_entered&&TaskValidate(editor))Yield;
  if(do_entered)m|=1;
  Kill(owner,TRUE,FALSE);
  if(!TaskValidate(owner))m|=2;
  if(!TaskValidate(editor)&&!do_returned)m|=4;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=8;
  if(do_ordered)m|=16;
  //A failing original keeps the borrower suspended in its callback. Never
  //resume it onto the retired document; the isolated reference guest ends.
  return m;
}
