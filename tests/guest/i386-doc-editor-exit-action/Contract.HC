I64 exit_action_calls;Bool exit_action_unlocked;
I64 ExitAction(CDoc *doc,CDocEntry *entry)
{
  no_warn entry;exit_action_calls++;
  exit_action_unlocked=!Bt(&doc->locked_flags,DOClf_LOCKED);
  return 73;
}
I64 DocEditorExitAction(Bool discard=FALSE)
{
  CDoc *target=DocNew,*source=DocNew,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry e,*current;I64 result,action=0,mask=0,a=0,b=0,msg;U8 *link;
  target->filename.name[0]=0;DocPrint(target,"alpha\n");DocTop(target);
  current=target->cur_entry;current->de_flags|=DOCEF_LEFT_CB;current->left_cb=&ExitAction;
  target->cmd_U8=CH_SPACE;link=MStrPrint("AI:%d",target);
  MemSet(&e,0,sizeof(e));e.de_flags=DOCEF_LINK|DOCEF_TAG;e.tag=link;source->cmd_U8=CH_SPACE;
  exit_action_calls=0;exit_action_unlocked=FALSE;FlushMsgs;
  if(discard)Msg(MSG_KEY_DOWN,CH_SHIFT_ESC,0);else Msg(MSG_KEY_DOWN,CH_ESC,0);
  result=DocEntryRun(source,&e,TRUE,&action);
  if(action && result && target->doc_signature==DOC_SIGNATURE_VAL)mask|=1;
  if(discard && !exit_action_calls || !discard && exit_action_calls==1 && exit_action_unlocked)mask|=2;
  msg=ScanMsg(&a,&b,1<<MSG_CMD);
  if(discard && !msg || !discard && msg==MSG_CMD && a==73 && !b)mask|=4;
  if(!Bt(&source->locked_flags,DOClf_LOCKED) && !Bt(&target->locked_flags,DOClf_LOCKED))mask|=8;
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=16;
  Free(link);FlushMsgs;DocDel(source);DocDel(target);return mask;
}
