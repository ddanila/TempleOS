U0 Report(U8 *text)
{
  while(*text) OutU8(0xE9,*text++);
}

U0 CheckOriginalBinSizeExeDoc()
{
  CDoc *doc=DocNew("T:/BinSizeExe.HC");
  CDocBin *bin=CAlloc(sizeof(CDocBin));
  CDocEntry *entry=CAlloc(sizeof(CDocEntry));
  I64 answer;
  bin->num=1; bin->size=3; bin->use_cnt=1;
  bin->data=MAlloc(3); bin->data[0]=1;
  QueIns(bin,doc->bin_head.last);
  entry->type=DOCT_INS_BIN_SIZE;
  entry->de_flags=DOCEF_TAG|DOCEF_HAS_BIN;
  entry->tag=StrNew(""); entry->bin_num=1; entry->bin_data=bin;
  DocInsEntry(doc,entry);
  DocPutKey(doc,';');
  answer=ExeDoc(doc);
  DocDel(doc);
  if(answer==3) Report("PASS original embedded binary size ExeDoc\n");
  else Report("FAIL original embedded binary size ExeDoc\n");
  Report("DONE original embedded binary size ExeDoc\n");
}

CheckOriginalBinSizeExeDoc;
