I64 dd_mode;
Bool dd_returned,dd_end_live;
CDoc *dd_target;
U0 DDEnd()
{dd_end_live=dd_target->doc_signature==DOC_SIGNATURE_VAL&&MHeapCtrl(dd_target)==Fs->parent_task->data_heap;}
U0 DDEditor(U8 *data)
{
  Fs->task_end_cb=&DDEnd;
  if(dd_mode==1)Fs->display_doc=dd_target;
  DocEd(data(CDoc *),DOF_DONT_SHOW|DOF_DONT_WINMGR_SYNC);
  dd_returned=TRUE;
}
I64 DDContract(I64 mode)
{
  CDoc *d=DocNew("Delete.DD"),*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *editor;
  I64 before,bytes,m=0;
  dd_mode=mode;dd_returned=dd_end_live=FALSE;
  if(mode==0)dd_target=d;
  else dd_target=DocNew("Target.DD");
  if(mode==2)d->parent_doc=dd_target;
  editor=Spawn(&DDEditor,d,"DocDel editor",-1,Fs);
  LBtr(&editor->display_flags,DISPLAYf_SHOW);
  while(TaskValidate(editor)&&(editor->display_doc!=d||!editor->border_doc))Yield;
  if(TaskValidate(editor)&&editor->display_doc==d)m|=1;
  bytes=DocSize(dd_target);before=Fs->data_heap->used_u8s;
  DocDel(dd_target);
  if(Fs->data_heap->used_u8s==before-bytes)m|=8;
  if(!TaskValidate(editor)&&!dd_returned)m|=2;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=4;
  if(dd_end_live)m|=32;
  if(mode==0){if(!TaskValidate(editor))m|=16;}
  else {
    if(d->doc_signature==DOC_SIGNATURE_VAL&&MHeapCtrl(d)==Fs->data_heap&&
        !Bt(&d->locked_flags,DOClf_LOCKED)&&d->win_task==Fs&&!d->parent_doc)m|=16;
    if(!TaskValidate(editor)){d->parent_doc=NULL;d->win_task=Fs;DocDel(d);}
  }
  //The isolated original control never resumes its editor onto deleted data.
  return m;
}
I64 DDCheck(I64 mode)
{I64 m=DDContract(mode);if(m!=63)throw('DocDelUI',TRUE);return m;}
