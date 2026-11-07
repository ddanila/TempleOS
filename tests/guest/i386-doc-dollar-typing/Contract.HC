U0 TDLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 TDFeed(CDoc *d,U8 *s){while(*s)DocPutKey(d,*s++);}
U8 td_lines[96];
Bool TDLine(CDoc *d,I64 index,U8 *wanted)
{
  U8 *s=DocScanLine(d,d->head.next);Bool okay=s&&!StrCmp(s,wanted);
  if(s && StrLen(s)<16)StrCpy(td_lines+index*16,s);
  Free(s);return okay;
}
#define FG 123
U0 TDCheck()
{
  CDoc *d=DocNew("TypedDollar.DD");I64 rows[6],i;U8 *s;
  MemSet(td_lines,0,sizeof(td_lines));d->flags|=DOCF_DONT_SWAP_OUT;
  TDFeed(d,"$$R");
  rows[0]=(d->flags&DOCF_IN_DOLLAR)!=0 && d->dollar_buf_ptr==2 && TDLine(d,0,"");
  TDFeed(d,"ED$$cash$$$$");
  rows[1]=TDLine(d,1,"cash$$") && !(d->flags&DOCF_IN_DOLLAR) && !d->dollar_buf_ptr &&
    d->head.next->type_u8==DOCT_FOREGROUND && d->head.next(CDocEntry *)->attr==RED;
  DocRst(d,TRUE);d->flags|=DOCF_DONT_SWAP_OUT;TDFeed(d,"$$FG,RED$$");
  rows[2]=TDLine(d,2,"") && d->head.next->type_u8==DOCT_FOREGROUND &&
    d->head.next(CDocEntry *)->attr==RED;
  DocRst(d,TRUE);d->flags|=DOCF_DONT_SWAP_OUT;
  TDFeed(d,"$$$$RED$$$$cash$$$$$$$$");rows[3]=TDLine(d,3,"$$RED$$cash$$$$");
  DocRst(d,TRUE);d->flags|=DOCF_DONT_SWAP_OUT|DOCF_PLAIN_TEXT;
  TDFeed(d,"$$RED$$cash$$$$");rows[4]=TDLine(d,4,"$$RED$$cash$$$$") && !(d->flags&DOCF_IN_DOLLAR);
  DocRst(d,TRUE);d->flags|=DOCF_DONT_SWAP_OUT;
  DocPutKey(d,36);for(i=0;i<200;i++)DocPutKey(d,120);
  rows[5]=d->dollar_buf_ptr==201 && d->dollar_buf_size>=203 && TDLine(d,5,"");
  DocDel(d);
  s=MStrPrint("EXPORT typed-dollar-rows.bin %X %X\n",rows,sizeof(rows));TDLog(s);Free(s);
  s=MStrPrint("EXPORT typed-dollar-lines.bin %X %X\n",td_lines,sizeof(td_lines));TDLog(s);Free(s);
  TDLog("DOC DOLLAR TYPING DONE\n");Sleep(1000);
}
