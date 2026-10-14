U0 Report(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 ExportLine(CDoc *d,U8 *name)
{
  U8 *s=DocScanLine(d,d->head.next),*msg;
  msg=MStrPrint("EXPORT %s %X %X\n",name,s,StrLen(s)+1);
  Report(msg);Free(msg);
}
U0 StreamCheck()
{
  CDoc *d=DocNew;
  U8 *s;
  DocPrintPartial(d,"left$$R");
  s=DocScanLine(d,d->head.next);
  if(StrCmp(s,"left") || !(d->flags&DOCF_IN_DOLLAR) || d->dollar_buf_ptr!=2) {
    Report("FAIL partial stream\n");return;
  }
  Free(s);
  DocPrintPartial(d,"ED$$cash$$");
  if(!(d->flags&DOCF_IN_DOLLAR) || d->dollar_buf_ptr!=1) {
    Report("FAIL split escape\n");return;
  }
  DocPrintPartial(d,"$$right");
  if(d->flags&DOCF_IN_DOLLAR || d->dollar_buf_ptr) {
    Report("FAIL completed stream\n");return;
  }
  ExportLine(d,"stream.bin");
  DocRst(d,TRUE);d->flags|=DOCF_PLAIN_TEXT;
  DocPrintPartial(d,"$$RED$$cash$$$$");
  ExportLine(d,"plain.bin");
  DocRst(d,TRUE);d->flags&=~DOCF_PLAIN_TEXT;
  DocPrintPartial(d,"abcd");
  d->cur_entry=d->head.next;d->cur_col=2;
  DocPrintPartial(d,"%s","XY");
  ExportLine(d,"insert.bin");
  DocDel(d);Report("PASS original document streaming\n");
}
StreamCheck;
Report("DONE original document streaming\n");
