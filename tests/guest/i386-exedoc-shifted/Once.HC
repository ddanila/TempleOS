U0 Report(U8 *text)
{
  while(*text) OutU8(0xE9,*text++);
}

U0 CheckQuotedShifted()
{
  CDoc *doc=DocNew("T:/QuotedShifted.HC");
  CDocEntry *entry;
  U8 *source="U8 *s=\"A",*tail="B\";Report(s);StrLen(s);",*line;
  I64 answer;
  while(*source) DocPutKey(doc,*source++);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_SHIFTED_X;
  entry->de_flags=doldoc.dft_de_flags[DOCT_SHIFTED_X];
  entry->attr=12;
  DocInsEntry(doc,entry);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_SHIFTED_Y;
  entry->de_flags=doldoc.dft_de_flags[DOCT_SHIFTED_Y];
  entry->attr=-34;
  DocInsEntry(doc,entry);
  while(*tail) DocPutKey(doc,*tail++);
  answer=ExeDoc(doc);
  line=MStrPrint("QUOTED SHIFTED LENGTH %d\n",answer);
  Report(line); Free(line);
  if(answer==17) Report("PASS original quoted shifted\n");
  else Report("FAIL original quoted shifted\n");
  DocDel(doc);
  Report("DONE quoted shifted\n");
}

CheckQuotedShifted;
