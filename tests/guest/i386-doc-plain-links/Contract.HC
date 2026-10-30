I64 DocPlainLinkSession(I64 mode,Bool lower=FALSE)
{
  CDoc *d,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry e;I64 result,action=0,mask=0,size=0;U8 *data,*link;
  U8 *name="C:/PlainTarget.DD",*initial="alpha\nbeta\n$RED$gamma\n";
  if(FileWrite(name,initial,StrLen(initial))>0)mask|=1;
  d=DocNew;MemSet(&e,0,sizeof(e));
  if(mode==0) {
    if(lower)link=MStrPrint("pi:%s",name);else link=MStrPrint("PI:%s",name);
  } else if(mode==1) {
    if(lower)link=MStrPrint("pf:%s,beta",name);else link=MStrPrint("PF:%s,beta",name);
  } else {
    if(lower)link=MStrPrint("pl:%s,2",name);else link=MStrPrint("PL:%s,2",name);
  }
  e.de_flags=DOCEF_LINK|DOCEF_TAG;e.tag=link;d->cmd_U8=CH_SPACE;
  FlushMsgs;Msg(MSG_KEY_DOWN,'Z',0);Msg(MSG_KEY_DOWN,CH_ESC,0);
  if(mode==3) { result=Plain(name);action=TRUE; }
  else result=DocEntryRun(d,&e,TRUE,&action);
  if(action && result)mask|=2;
  if(!Bt(&d->locked_flags,DOClf_LOCKED))mask|=4;
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=8;
  data=FileRead(name,&size);
  if(data && size && StrMatch("$RED$gamma",data)) {
    if((mode==0 || mode==3) && StrMatch("Zalpha\nbeta",data))mask|=16;
    if((mode==1 || mode==2) && StrMatch("alpha\nZbeta",data))mask|=16;
  }
  Free(data);Free(link);FlushMsgs;DocDel(d);
  return mask;
}
