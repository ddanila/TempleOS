I64 JRContract(I64 unused)
{
  I64 mask=0,base=Fs->data_heap->used_u8s;
  CDoc *doc=DocNew;
  DocPrint(doc,"Alpha\nBeta\nBeta\n$$AN,\"\",A=\"Target\"$$End\n");
  if(!DocGoToLine(NULL,2) && !DocFind(NULL,,"Beta") && !DocAnchorFind(NULL,"Target"))mask|=1;
  if(DocGoToLine(doc,2) && doc->cur_entry->y==1)mask|=2;
  if(DocFind(doc,,"beta",2) && doc->cur_entry->tag && !StrCmp(doc->cur_entry->tag,"Beta"))mask|=4;
  if(DocAnchorFind(doc,"Target") && doc->cur_entry->type_u8==DOCT_ANCHOR && !StrCmp(doc->cur_entry->aux_str,"Target"))mask|=8;
  if(!DocFind(doc,,"Missing") && !DocAnchorFind(doc,"Missing"))mask|=16;
  DocDel(doc);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
