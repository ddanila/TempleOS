U0 Report(U8 *text)
{
  while(*text) OutU8(0xE9,*text++);
}

U0 CheckQuotedLayout()
{
  CDoc *doc=DocNew("T:/QuotedLayout.HC");
  CDocEntry *entry;
  U8 *source="U8 *s=\"A",*tail="B\";Report(s);StrLen(s);",*line;
  I64 answer;
  while(*source) DocPutKey(doc,*source++);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_PAGE_LEN;
  entry->de_flags=doldoc.dft_de_flags[DOCT_PAGE_LEN];
  entry->attr=80;
  DocInsEntry(doc,entry);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_LEFT_MARGIN;
  entry->de_flags=doldoc.dft_de_flags[DOCT_LEFT_MARGIN];
  entry->attr=-2;
  DocInsEntry(doc,entry);
  while(*tail) DocPutKey(doc,*tail++);
  answer=ExeDoc(doc);
  line=MStrPrint("QUOTED LAYOUT LENGTH %d\n",answer);
  Report(line); Free(line);
  if(answer==16) Report("PASS original quoted layout\n");
  else Report("FAIL original quoted layout\n");
  DocDel(doc);
  Report("DONE quoted layout\n");
}

CheckQuotedLayout;
