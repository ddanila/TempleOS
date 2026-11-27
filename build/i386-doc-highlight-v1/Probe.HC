U0 DocHighlightProbe()
{
  CDoc *doc=DocNew;
  CDocEntry *entry;
  U8 *source="// highlight me";
  U32 *run;
  U8 *message,*cursor;
  DocPrint(doc,"%s",source);
  entry=doc->head.next;
  run=DocHighlight(entry,source,StrLen(source),0);
  message=MStrPrint("EXPORT Highlight.bin %X %X\n",run,(StrLen(source)+1)*sizeof(U32));
  cursor=message;
  while (*cursor) OutU8(0xE9,*cursor++);
  Sleep(1000);
  Free(message);
  Free(run);
  DocDel(doc);
  cursor="DONE DocHighlight probe\n";
  while (*cursor) OutU8(0xE9,*cursor++);
}
DocHighlightProbe;
