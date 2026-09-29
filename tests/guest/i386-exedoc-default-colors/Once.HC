U0 Report(U8 *text)
{
  while(*text) OutU8(0xE9,*text++);
}

U0 CheckQuotedDefaultColors()
{
  CDoc *doc=DocNew("T:/QuotedDefaultColors.HC");
  CDocEntry *entry;
  U8 *source="U8 *s=\"A",*tail="B\";Report(s);StrLen(s);",*line;
  I64 answer;
  while(*source) DocPutKey(doc,*source++);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_DFT_FOREGROUND;
  entry->de_flags=doldoc.dft_de_flags[DOCT_DFT_FOREGROUND];
  entry->attr=7;
  DocInsEntry(doc,entry);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_DFT_BACKGROUND;
  entry->de_flags=doldoc.dft_de_flags[DOCT_DFT_BACKGROUND];
  entry->attr=2;
  DocInsEntry(doc,entry);
  while(*tail) DocPutKey(doc,*tail++);
  answer=ExeDoc(doc);
  line=MStrPrint("QUOTED DEFAULT COLORS LENGTH %d\n",answer);
  Report(line); Free(line);
  if(answer==14) Report("PASS original quoted default colors\n");
  else Report("FAIL original quoted default colors\n");
  DocDel(doc);
  Report("DONE quoted default colors\n");
}

CheckQuotedDefaultColors;
