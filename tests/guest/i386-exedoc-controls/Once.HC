U0 Report(U8 *text)
{
  while(*text) OutU8(0xE9,*text++);
}

U0 CheckQuotedControls()
{
  CDoc *doc=DocNew("T:/QuotedControls.HC");
  CDocEntry *entry;
  U8 *source="U8 *s=\"A",*tail="B\";Report(s);StrLen(s);",*line;
  I64 answer;
  while(*source) DocPutKey(doc,*source++);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_PAGE_BREAK;
  entry->de_flags=doldoc.dft_de_flags[DOCT_PAGE_BREAK];
  DocInsEntry(doc,entry);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_CLEAR;
  entry->de_flags=doldoc.dft_de_flags[DOCT_CLEAR];
  DocInsEntry(doc,entry);
  while(*tail) DocPutKey(doc,*tail++);
  answer=ExeDoc(doc);
  line=MStrPrint("QUOTED CONTROLS LENGTH %d\n",answer);
  Report(line); Free(line);
  DocDel(doc);
  Report("DONE quoted controls\n");
}

CheckQuotedControls;
