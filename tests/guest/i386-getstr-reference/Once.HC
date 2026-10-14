//Run against the original kernel/compiler and repaired original assets.
U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }
U0 CaptureStr(U8 *name,U8 *input,U8 *dft=NULL,I64 flags=0)
{
  U8 *st,*line;
  DocClear;
  In("%s",input);
  st=GetStr(NULL,dft,flags);
  line=MStrPrint("EXPORT %s %X %X\n",name,st,StrLen(st)+1);
  Report(line); Free(line);
  //Keep exported memory alive until the host has captured it.
}
CaptureStr("single.bin","alpha\n");
CaptureStr("empty.bin","\n");
CaptureStr("default.bin","\n","fallback");
CaptureStr("multiline.bin","alpha\nbeta\n\x1B",NULL,GSF_WITH_NEW_LINE);
CaptureStr("cancel.bin","discard\x1C");
CaptureStr("cancel-default.bin","discard\x1C","fallback");
U0 CaptureDocLine()
{
  CDoc *doc=DocNew;
  CDocEntry *end;
  U8 *st,*line;
  I64 col;
  st=DocScanLine(doc,doc,&col,&end);
  if(*st || col!=0 || end!=doc) {Report("FAIL empty DocScanLine\n");return;}
  line=MStrPrint("EXPORT scan-empty.bin %X %X\n",st,StrLen(st)+1);
  Report(line); Free(line);
  DocPutS(doc,"alpha\tbeta\nsecond");
  doc->cur_entry=doc->head.next; doc->cur_col=2;
  st=DocScanLine(doc,doc->head.next,&col,&end);
  if(col!=2 || end->type_u8!=DOCT_NEW_LINE) {Report("FAIL first DocScanLine\n");return;}
  line=MStrPrint("EXPORT scan-first.bin %X %X\n",st,StrLen(st)+1);
  Report(line); Free(line);
  st=DocScanLine(doc,end->next,NULL,&end);
  if(end!=doc) {Report("FAIL final DocScanLine\n");return;}
  line=MStrPrint("EXPORT scan-second.bin %X %X\n",st,StrLen(st)+1);
  Report(line); Free(line);
  DocRst(doc,TRUE);
  DocPutS(doc,"$$SX,-3$$$$SY,2$$");
  if(doc->head.next->type_u8!=DOCT_SHIFTED_X ||
      doc->head.next->next->type_u8!=DOCT_SHIFTED_Y) {
    Report("FAIL shifted entry types\n");return;
  }
  st=DocScanLine(doc,doc->head.next,NULL,&end);
  if(end!=doc) {Report("FAIL shifted DocScanLine\n");return;}
  line=MStrPrint("EXPORT scan-shift.bin %X %X\n",st,StrLen(st)+1);
  Report(line); Free(line);
  DocDel(doc);
}
CaptureDocLine;
Report("DONE original GetStr and document line extraction\n");
