U0 Report(U8 *text)
{
  while(*text) OutU8(0xE9,*text++);
}

U0 AddLayout(CDoc *doc,I64 type,I64 attr)
{
  CDocEntry *entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=type;
  entry->de_flags=doldoc.dft_de_flags[type];
  entry->attr=attr;
  DocInsEntry(doc,entry);
}

U0 CheckQuotedLayoutAll()
{
  CDoc *doc=DocNew("T:/QuotedLayoutAll.HC");
  I64 answer;
  U8 *source="U8 *s=\"A",*tail="B\";Report(s);StrLen(s);",*line;
  while(*source) DocPutKey(doc,*source++);
  AddLayout(doc,DOCT_PAGE_LEN,80);
  AddLayout(doc,DOCT_LEFT_MARGIN,-2);
  AddLayout(doc,DOCT_RIGHT_MARGIN,3);
  AddLayout(doc,DOCT_HEADER,4);
  AddLayout(doc,DOCT_FOOTER,5);
  AddLayout(doc,DOCT_INDENT,6);
  AddLayout(doc,DOCT_WORD_WRAP,1);
  AddLayout(doc,DOCT_HIGHLIGHT,1);
  while(*tail) DocPutKey(doc,*tail++);
  answer=ExeDoc(doc);
  line=MStrPrint("QUOTED LAYOUT ALL LENGTH %d\n",answer);
  Report(line); Free(line);
  DocDel(doc);
  Report("DONE quoted layout all\n");
}

CheckQuotedLayoutAll;
