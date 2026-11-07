U0 THLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 THOne(I64 mode)
{
  CTask *child=NULL,*popup=Fs->popup_task,*focus=sys_focus_task;
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder,*borrowed=NULL;
  I64 records[3],mask=0,size,deadline;U8 *code,*text,*s,*prefix;
  MemSet(records,0,sizeof(records));
  prefix=StrNew("");
  if(mode) {
    borrowed=DocNew("BorrowedHandoff.DD");Free(prefix);
    prefix=MStrPrint("Fs->put_doc=Fs->display_doc=%d;Fs->put_doc->win_task=Fs;",borrowed);
  }
  code=MStrPrint("%s\"Handoff sentinel\\n$$LK,\\\"Keep link\\\",A=\\\"FI:::/Doc/HelpIndex.DD\\\"$$\\n\";"
      "*(%d)(I64*)=DocPut;*(%d)(I64*)=DocDisplay;*(%d)(I64*)=DocBorder;UserTaskCont;",
      prefix,&records[0],&records[1],&records[2]);Free(prefix);
  PopUp(code,NULL,&child);Free(code);
  deadline=cnts.jiffies+30000;
  while(TaskValidate(child) && !Bt(&child->task_flags,TASKf_CMD_LINE_PMT) && cnts.jiffies<deadline)Yield;
  if(!TaskValidate(child) || !Bt(&child->task_flags,TASKf_CMD_LINE_PMT))throw('Handoff',TRUE);
  if(child->put_doc==records[0])mask|=1;
  if(child->display_doc==records[1])mask|=2;
  if(child->border_doc==records[2])mask|=4;
  text=DocSave(child->put_doc,&size);
  if(StrFind("Handoff sentinel",text) && StrFind("Keep link",text) && StrFind("FI:::/Doc/HelpIndex.DD",text))mask|=8;
  s=MStrPrint("EXPORT handoff-%d.DD %X %X\nHANDOFF MASK %d %d\n",mode,text,size,mode,mask);THLog(s);Free(s);
  WinFocus(child);s=MStrPrint("HANDOFF READY %d\n",mode);THLog(s);Free(s);Sleep(1000);Free(text);
  while(TaskValidate(child))Yield;
  if(DocPut==put && DocDisplay==display && DocBorder==border && Fs->popup_task==popup)mask|=16;
  if(TaskValidate(focus))WinFocus(focus);
  if(borrowed) {
    if(borrowed->doc_signature!=DOC_SIGNATURE_VAL)throw('Borrowed',TRUE);
    borrowed->win_task=Fs; //The owner reclaims its display role after child exit.
    text=DocSave(borrowed,&size);
    if(StrFind("Handoff sentinel",text) && StrFind("Keep link",text))mask|=32;
    Free(text);DocDel(borrowed);
  }
  return mask;
}
U0 THCheck()
{
  I64 masks[2],i;U8 *s;
  for(i=0;i<2;i++)masks[i]=THOne(i);
  s=MStrPrint("EXPORT handoff-mask.bin %X %X\nHANDOFF DONE\n",masks,sizeof(masks));THLog(s);Free(s);Sleep(1000);
}
