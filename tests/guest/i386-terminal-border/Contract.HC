I64 JRContract()
{
  CDoc *doc,*border;
  CDocEntry *entry;
  U8 *text;
  I64 mask=0,callbacks=0,title=0,base=Fs->data_heap->used_u8s;
  doc=DocNew;border=DocBorderNew(doc);
  for(entry=border->head.next;entry!=border;entry=entry->next) {
    if(entry->tag_cb&&entry->user_data==doc)callbacks++;
    if(entry->type_u8==DOCT_DATA&&entry->data==&Fs->task_title)title++;
  }
  if(callbacks==5)mask|=1;
  if(title==1)mask|=2;
  if(border->flags&DOCF_BORDER_DOC)mask|=4;
  entry=DocEntryNewTag(border,border," ");entry->user_data=doc;
  doc->flags|=DOCF_OVERSTRIKE;
  text=EdOverStrikeCB(border,entry,Fs);
  if(text[0]=='O'&&!text[1])mask|=8;
  Free(text);
  doc->flags|=DOCF_IN_DOLLAR;
  text=EdDollarCB(border,entry,Fs);
  if(text[0]=='$$'&&!text[1])mask|=16;
  Free(text);
  text=EdDollarTypeCB(border,entry,Fs);
  if(!StrCmp(text,"EOF"))mask|=32;
  Free(text);
  DocEntryDel(border,entry);
  DocDel(border);DocDel(doc);
  return mask;
}
