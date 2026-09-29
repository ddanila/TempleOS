U0 Report(U8 *text)
{
  while(*text) OutU8(0xE9,*text++);
}

U0 CheckQuotedDocumentFormat()
{
  CDoc *doc=DocNew("T:/QuotedFormat.HC");
  CDocEntry *entry;
  U8 *source="U8 *s=\"A",*tail="B\";Report(s);StrLen(s);",*line;
  I64 answer;
  while(*source) DocPutKey(doc,*source++);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_FOREGROUND;
  entry->de_flags=doldoc.dft_de_flags[DOCT_FOREGROUND];
  entry->attr=4;
  DocInsEntry(doc,entry);
  while(*tail) DocPutKey(doc,*tail++);
  answer=ExeDoc(doc);
  line=MStrPrint("QUOTED FORMAT LENGTH %d\n",answer);
  Report(line); Free(line);
  if(answer==8) Report("PASS original quoted document format\n");
  else Report("FAIL original quoted document format\n");
  DocDel(doc);
  Report("DONE quoted document format\n");
}

CheckQuotedDocumentFormat;
