U0 Report(U8 *text)
{
  while(*text) OutU8(0xE9,*text++);
}

U0 CheckQuotedBackground()
{
  CDoc *doc=DocNew("T:/QuotedBackground.HC");
  CDocEntry *entry;
  U8 *source="U8 *s=\"A",*tail="B\";Report(s);StrLen(s);",*line;
  I64 answer;
  while(*source) DocPutKey(doc,*source++);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_BACKGROUND;
  entry->de_flags=doldoc.dft_de_flags[DOCT_BACKGROUND];
  entry->attr=1;
  DocInsEntry(doc,entry);
  while(*tail) DocPutKey(doc,*tail++);
  answer=ExeDoc(doc);
  line=MStrPrint("QUOTED BACKGROUND LENGTH %d\n",answer);
  Report(line); Free(line);
  if(answer==8) Report("PASS original quoted background\n");
  else Report("FAIL original quoted background\n");
  DocDel(doc);
  Report("DONE quoted background\n");
}

CheckQuotedBackground;
