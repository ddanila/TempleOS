CDoc *od_doc;
Bool od_returned,od_end_live;
U0 ODEnd()
{od_end_live=od_doc->doc_signature==DOC_SIGNATURE_VAL&&MHeapCtrl(od_doc)==Fs->data_heap;}
U0 ODEditor(U8 *data)
{
  CDocEntry *e;
  od_doc=DocNew("Owned.DD");
  e=DocPrint(od_doc,"$$TX,\"Owned\"$$");
  e->data=data;e->de_flags|=DOCEF_REMALLOC_DATA;
  Fs->task_end_cb=&ODEnd;
  DocEd(od_doc,DOF_DONT_SHOW|DOF_DONT_WINMGR_SYNC);od_returned=TRUE;
  while(TRUE)Yield;
}
I64 ODContract()
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *editor,*old_child=Fs->next_child_task;
  U8 *external=MAlloc(32);
  I64 external_bytes=MSize2(external),before,m=0,i;
  od_doc=NULL;od_returned=od_end_live=FALSE;
  editor=Spawn(&ODEditor,external,"Owned DocDel",-1,Fs);
  LBtr(&editor->display_flags,DISPLAYf_SHOW);
  while(TaskValidate(editor)&&(!od_doc||editor->display_doc!=od_doc||!editor->border_doc))Yield;
  if(TaskValidate(editor)&&od_doc&&editor->display_doc==od_doc)m|=1;
  if(od_doc->doc_signature==DOC_SIGNATURE_VAL&&MHeapCtrl(od_doc)==editor->data_heap)m|=2;
  before=Fs->data_heap->used_u8s;
  DocDel(od_doc);
  if(!TaskValidate(editor)&&!od_returned)m|=4;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=8;
  if(od_end_live)m|=16;
  if(Fs->data_heap->used_u8s==before-external_bytes)m|=32;
  for(i=0;i<200&&Fs->next_child_task!=old_child;i++)Sleep(5);
  if(Fs->next_child_task==old_child)m|=64;
  return m;
}
I64 ODCheck()
{I64 m=ODContract;if(m!=127)throw('OwnedDel',TRUE);return m;}
