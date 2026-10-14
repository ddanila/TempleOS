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
I64 sh_mode,sh_calls;
Bool sh_text,sh_data,sh_locked;
Bool SHHook(CDoc *d,U8 *data,U8 *text)
{
  sh_calls++;sh_text=StrCmp(text,"abc7")==0;
  sh_data=data==&sh_mode;sh_locked=Bt(&d->locked_flags,DOClf_LOCKED);
  return sh_mode==1;
}
U0 CallbackCheck()
{
  CDoc *d=DocNew;
  U8 *text,*want;
  I64 mode;
  d->user_put_s=&SHHook;d->user_put_data=&sh_mode;
  for(mode=1;mode>=0;mode--) {
    sh_mode=mode;sh_calls=0;sh_text=sh_data=sh_locked=FALSE;
    DocPrintPartial(d,"%s%d","abc",7);
    text=DocScanLine(d,d->head.next);
    want="abc7";if(mode==1)want="";
    if(sh_calls!=1 || !sh_text || !sh_data || sh_locked || d->owning_task ||
        StrCmp(text,want)) {
      Report("FAIL original streaming callback\n");return;
    }
    Free(text);
  }
  DocDel(d);Report("PASS original streaming callback\n");
}
StreamCheck;
CallbackCheck;
Report("DONE original document streaming\n");
