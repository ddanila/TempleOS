I64 DocPrefixedLinkSession()
{
  CDoc *d,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry e;I64 result,action=0,mask=0,size=0;U8 *data;
  U8 *name="C:/LinkTarget.DD",*initial="alpha\n",*link;
  if(FileWrite(name,initial,StrLen(initial))>0)mask|=1;
  d=DocNew;MemSet(&e,0,sizeof(e));
  link=MStrPrint("FI:%s",name);
  e.de_flags=DOCEF_LINK|DOCEF_TAG;e.tag=link;d->cmd_U8=CH_SPACE;
  FlushMsgs;Msg(MSG_KEY_DOWN,'Z',0);Msg(MSG_KEY_DOWN,CH_ESC,0);
  result=DocEntryRun(d,&e,TRUE,&action);
  if(action && result)mask|=2;
  if(!Bt(&d->locked_flags,DOClf_LOCKED))mask|=4;
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=8;
  data=FileRead(name,&size);
  if(data && size && StrOcc(data,'Z'))mask|=16;
  Free(data);Free(link);FlushMsgs;DocDel(d);
  return mask;
}
