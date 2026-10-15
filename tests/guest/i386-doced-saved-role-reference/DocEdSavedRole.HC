I64 sr_mode;
Bool sr_returned,sr_custom_seen;
CDoc *sr_custom;
CDoc *sr_saved;
U0 SRHold(U8 *data){while(TRUE)Yield;}
U8 *SRTag(CDoc *d,CDocEntry *e,CTask *mem)
{
  if(sr_mode==5&&Fs->display_doc==d){
    d->parent_doc=sr_custom;sr_custom_seen=TRUE;while(TRUE)Yield;
  }
  return StrNew("Custom",mem);
}
U0 SREditor(U8 *data)
{
  if(sr_mode==0)Fs->put_doc=sr_saved;
  else if(sr_mode==1||sr_mode==4||sr_mode==5)Fs->display_doc=sr_saved;
  else if(sr_mode==2)Fs->border_doc=sr_saved;
  if(sr_mode==5)Msg(MSG_KEY_DOWN,CH_ESC,0);
  DocEd(data(CDoc *),DOF_DONT_SHOW|DOF_DONT_WINMGR_SYNC);
  sr_returned=TRUE;
}
I64 SRContract(I64 mode)
{
  CTask *owner,*editor;
  CDoc *d=DocNew("Survivor.DD"),*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDoc *parent=NULL;
  I64 m=0;
  sr_mode=mode;sr_returned=sr_custom_seen=FALSE;sr_custom=NULL;
  owner=Spawn(&SRHold,NULL,"Saved role owner",-1,Fs);
  LBtr(&owner->display_flags,DISPLAYf_SHOW);
  sr_saved=DocNew("Saved.DD",owner);
  if(mode==2)sr_saved->flags|=DOCF_BORDER_DOC;
  if(mode==3)d->parent_doc=sr_saved;
  if(mode==4||mode==5){parent=DocNew("Parent.DD");d->parent_doc=parent;}
  if(mode==5){
    CDocEntry *entry;
    sr_custom=DocNew("Custom.DD");
    entry=DocPrint(d,"$$TX+TC,\"Custom\"$$");entry->tag_cb=&SRTag;
  }
  editor=Spawn(&SREditor,d,"Saved role editor",-1,Fs);
  LBtr(&editor->display_flags,DISPLAYf_SHOW);
  if(mode==5){while(TaskValidate(editor)&&!sr_custom_seen)Yield;}
  else {while(TaskValidate(editor)&&(editor->display_doc!=d||!editor->border_doc))Yield;}
  if(TaskValidate(editor)&&editor->display_doc==d)m|=1;
  Kill(owner,TRUE,FALSE);
  if(!TaskValidate(owner))m|=2;
  if(!TaskValidate(editor)&&!sr_returned)m|=4;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=8;
  if(d->doc_signature==DOC_SIGNATURE_VAL&&MHeapCtrl(d)==Fs->data_heap)m|=16;
  if(!Bt(&d->locked_flags,DOClf_LOCKED))m|=32;
  if(d->win_task==Fs)m|=64;
  if(mode==4){if(d->parent_doc==parent&&parent->doc_signature==DOC_SIGNATURE_VAL)m|=128;}
  else if(mode==5){if(d->parent_doc==sr_custom&&sr_custom->doc_signature==DOC_SIGNATURE_VAL)m|=128;}
  else if(!d->parent_doc)m|=128;
  if(!TaskValidate(editor)){
    //Record dangling-parent failures before repairing the isolated fixture.
    d->parent_doc=NULL;d->win_task=Fs;DocDel(d);
    if(parent)DocDel(parent);
    if(sr_custom)DocDel(sr_custom);
  }
  return m;
}
I64 SRCheck(I64 mode)
{I64 m=SRContract(mode);if(m!=255)throw('RoleLife',TRUE);return m;}
