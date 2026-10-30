I64 DocSymbolLinkSession(Bool lower=FALSE)
{
  CDoc *target=DocNew,*source=DocNew,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry e;CHashDefineStr *symbol;I64 result,action=0,mask=0,size=0;U8 *data,*link;
  target->filename.name[0]=0;DocPrint(target,"alpha\nbeta\ngamma\n");DocTop(target);
  symbol=DefineLoad("MN_LINK_TEST","unused");Free(symbol->src_link);
  symbol->src_link=MStrPrint("AL:%d,2",target);
  if(lower)link=StrNew("mn:MN_LINK_TEST");else link=StrNew("MN:MN_LINK_TEST");
  if(symbol && target->doc_signature==DOC_SIGNATURE_VAL)mask|=1;
  MemSet(&e,0,sizeof(e));e.de_flags=DOCEF_LINK|DOCEF_TAG;e.tag=link;source->cmd_U8=CH_SPACE;
  FlushMsgs;Msg(MSG_KEY_DOWN,'Z',0);Msg(MSG_KEY_DOWN,CH_ESC,0);
  result=DocEntryRun(source,&e,TRUE,&action);
  if(action && result && target->doc_signature==DOC_SIGNATURE_VAL)mask|=2;
  if(!Bt(&source->locked_flags,DOClf_LOCKED) && !Bt(&target->locked_flags,DOClf_LOCKED))mask|=4;
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=8;
  data=DocSave(target,&size);
  if(data && size && StrMatch("alpha\nZ",data) && StrMatch("beta\ngamma",data))mask|=16;
  Free(data);Free(link);HashRemDel(symbol,Fs->hash_table);FlushMsgs;DocDel(source);DocDel(target);
  return mask;
}

Bool DocSymbolLinkMissing()
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  return !Ed("MN:MN_LINK_MISSING",EDF_BAIL) && DocPut==put &&
    DocDisplay==display && DocBorder==border;
}
