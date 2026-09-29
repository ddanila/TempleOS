U0 Report(U8 *text)
{
  while(*text) OutU8(0xE9,*text++);
}

U0 CheckQuotedStyles()
{
  CDoc *doc=DocNew("T:/QuotedStyles.HC");
  CDocEntry *entry;
  U8 *source="U8 *s=\"A",*tail="B\";Report(s);StrLen(s);",*line;
  I64 answer;
  while(*source) DocPutKey(doc,*source++);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_BLINK; entry->de_flags=doldoc.dft_de_flags[DOCT_BLINK];
  entry->attr=1; DocInsEntry(doc,entry);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_INVERT; entry->de_flags=doldoc.dft_de_flags[DOCT_INVERT];
  entry->attr=1; DocInsEntry(doc,entry);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_UNDERLINE; entry->de_flags=doldoc.dft_de_flags[DOCT_UNDERLINE];
  entry->attr=1; DocInsEntry(doc,entry);
  while(*tail) DocPutKey(doc,*tail++);
  answer=ExeDoc(doc);
  line=MStrPrint("QUOTED STYLES LENGTH %d\n",answer);
  Report(line); Free(line);
  if(answer==20) Report("PASS original quoted styles\n");
  else Report("FAIL original quoted styles\n");
  DocDel(doc);
  Report("DONE quoted styles\n");
}

CheckQuotedStyles;
