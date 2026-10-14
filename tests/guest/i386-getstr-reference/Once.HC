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
CaptureStr("backspace.bin","abc\x08Z\n");
CaptureStr("erased-default.bin","abc\x08\x08\x08\n","fallback");
CaptureStr("tab.bin","alpha\tbeta\n");
CaptureStr("spaces.bin","  alpha  \n");
CaptureStr("markup.bin","$$RED$$cash$$$$\n");
CaptureStr("dollars.bin","$$$$RED$$$$cash$$$$$$$$\n");
CaptureStr("extended.bin","\x82\xA3\n");
#define FG 123
U0 CaptureDollarKeys()
{
  CDoc *doc=DocNew;
  U8 *ptr="$$R",*st,*line;
  I64 i;
  while(*ptr) DocPutKey(doc,*ptr++);
  st=DocScanLine(doc,doc->head.next);
  if(!(doc->flags&DOCF_IN_DOLLAR) || doc->dollar_buf_ptr!=2 || *st) {
    Report("FAIL partial typed dollar\n");return;
  }
  Free(st);ptr="ED$$cash$$$$";
  while(*ptr) DocPutKey(doc,*ptr++);
  if(doc->flags&DOCF_IN_DOLLAR || doc->dollar_buf_ptr ||
      doc->head.next->type_u8!=DOCT_FOREGROUND || doc->head.next(CDocEntry *)->attr!=RED) {
    Report("FAIL completed typed dollar\n");return;
  }
  st=DocScanLine(doc,doc->head.next);
  line=MStrPrint("EXPORT dollar-keys.bin %X %X\n",st,StrLen(st)+1);
  Report(line);Free(line);
  DocRst(doc,TRUE);ptr="$$FG,RED$$";
  while(*ptr) DocPutKey(doc,*ptr++);
  if(doc->head.next->type_u8!=DOCT_FOREGROUND ||
      doc->head.next(CDocEntry *)->attr!=RED) {
    Report("FAIL dollar command/attribute macro distinction\n");return;
  }
  DocRst(doc,TRUE);doc->flags|=DOCF_PLAIN_TEXT;
  ptr="$$RED$$cash$$$$";
  while(*ptr) DocPutKey(doc,*ptr++);
  st=DocScanLine(doc,doc->head.next);
  line=MStrPrint("EXPORT dollar-plain.bin %X %X\n",st,StrLen(st)+1);
  Report(line);Free(line);
  DocRst(doc,TRUE);
  DocPutKey(doc,'$$');
  for(i=0;i<200;i++) DocPutKey(doc,'x');
  if(doc->dollar_buf_ptr!=201 || doc->dollar_buf_size<203) {
    Report("FAIL typed dollar growth\n");return;
  }
  DocDel(doc);
  Report("PASS original typed dollar state and growth\n");
}
CaptureDollarKeys;
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
