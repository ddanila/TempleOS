I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,mask=0,flags;
  CDoc *doc=DocNew;
  CDocEntry *entry=DocPrint(doc,"$$LK,\"label\",A=\"C:/Example.HC\"$$");
  U8 *link;
  flags=entry->de_flags;
  link=DocEntryLink(doc,entry);
  if(link && !StrCmp(link,"C:/Example.HC") && link!=entry->aux_str)mask|=1;
  Free(link);
  entry->de_flags=flags&~DOCEF_AUX_STR;
  link=DocEntryLink(doc,entry);
  if(link && !StrCmp(link,"label") && link!=entry->tag)mask|=2;
  Free(link);
  entry->de_flags=flags&~DOCEF_LINK;
  if(!DocEntryLink(doc,entry))mask|=4;
  entry->de_flags=flags&~(DOCEF_TAG|DOCEF_AUX_STR);
  if(!DocEntryLink(doc,entry))mask|=8;
  entry->de_flags=flags;DocDel(doc);
  if(Fs->data_heap->used_u8s==base)mask|=16;
  return mask;
}
