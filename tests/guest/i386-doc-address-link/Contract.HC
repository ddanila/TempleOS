I64 DocAddressTarget(){return 42;}
I64 DocAddressLinkSession(Bool lower=FALSE)
{
  CDoc *source=DocNew,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry e;CHashSrcSym *symbol=HashFind("DocAddressTarget",Fs->hash_table,HTT_FUN);
  CDbgInfo *old_dbg;U8 *old_link,*data,*link,*name="C:/AddressTarget.DD",*initial="alpha\nbeta\ngamma\n";
  I64 result,action=0,mask=0,size=0;
  if(!symbol) {DocDel(source);return 0;}
  if(FileWrite(name,initial,StrLen(initial))>0)mask|=1;
  old_link=symbol->src_link;old_dbg=symbol->dbg_info;
  symbol->src_link=MStrPrint("FL:%s,2",name);symbol->dbg_info=NULL;
  if(lower)link=StrNew("ad:&DocAddressTarget,64");else link=StrNew("AD:&DocAddressTarget,64");
  MemSet(&e,0,sizeof(e));e.de_flags=DOCEF_LINK|DOCEF_TAG;e.tag=link;source->cmd_U8=CH_SPACE;
  FlushMsgs;Msg(MSG_KEY_DOWN,'Z',0);Msg(MSG_KEY_DOWN,CH_ESC,0);
  result=DocEntryRun(source,&e,TRUE,&action);
  if(action && result)mask|=2;
  if(!Bt(&source->locked_flags,DOClf_LOCKED))mask|=4;
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=8;
  data=FileRead(name,&size);
  if(data && size && StrMatch("alpha\nZ",data) && StrMatch("beta\ngamma",data))mask|=16;
  Free(data);Free(link);Free(symbol->src_link);symbol->src_link=old_link;symbol->dbg_info=old_dbg;
  FlushMsgs;DocDel(source);return mask;
}
Bool DocAddressLinkMissing()
{ return !Ed("AD:0",EDF_BAIL); }
