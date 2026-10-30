I64 DocMemoryLinkSession(I64 mode,Bool lower=FALSE)
{
  CDoc *target=DocNew,*source=DocNew,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry e;I64 result,action=0,mask=0,size=0;U8 *data,*link;
  target->filename.name[0]=0;
  DocPrint(target,"alpha\nbeta\n$$AN,\"\",A=\"Target\"$$gamma\n");
  DocTop(target);
  if(target->doc_signature==DOC_SIGNATURE_VAL && source->left_click_link)mask|=1;
  if(mode==0) {
    if(lower)link=MStrPrint("ai:%d",target);else link=MStrPrint("AI:%d",target);
  } else if(mode==1) {
    if(lower)link=MStrPrint("aa:%d,Target",target);else link=MStrPrint("AA:%d,Target",target);
  } else if(mode==2) {
    if(lower)link=MStrPrint("af:%d,beta",target);else link=MStrPrint("AF:%d,beta",target);
  } else {
    if(lower)link=MStrPrint("al:%d,2",target);else link=MStrPrint("AL:%d,2",target);
  }
  MemSet(&e,0,sizeof(e));e.de_flags=DOCEF_LINK|DOCEF_TAG;e.tag=link;source->cmd_U8=CH_SPACE;
  FlushMsgs;Msg(MSG_KEY_DOWN,'Z',0);Msg(MSG_KEY_DOWN,CH_ESC,0);
  result=DocEntryRun(source,&e,TRUE,&action);
  if(action && result && target->doc_signature==DOC_SIGNATURE_VAL)mask|=2;
  if(!Bt(&source->locked_flags,DOClf_LOCKED) && !Bt(&target->locked_flags,DOClf_LOCKED))mask|=4;
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=8;
  data=DocSave(target,&size);
  if(data && size && StrMatch("Target",data) && StrMatch("gamma\n",data)) {
    if(mode==0 && *data=='Z')mask|=16;
    if(mode==1 && StrMatch("alpha\nbeta\nZ",data))mask|=16;
    if(mode>=2 && StrMatch("alpha\nZ",data))mask|=16;
  }
  Free(data);Free(link);FlushMsgs;DocDel(source);DocDel(target);
  return mask;
}
