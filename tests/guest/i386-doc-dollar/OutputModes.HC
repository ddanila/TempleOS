I64 DollarParserContract()
{
  I64 mask=0;
  CDoc *d;
  CDocEntry *e;
  U8 *s;
  U8 cursor[4];
  d=DocNew("C:/Output.DD",Fs);s=StrNew("abc");
  e=DocPutS(d,s);
  if(!e&&d->head.next->type_u8==DOCT_TEXT&&StrCmp(d->head.next->tag,"abc")==0&&StrCmp(s,"abc")==0)mask|=1;
  Free(s);DocDel(d);
  d=DocNew("C:/Output.DD",Fs);s=StrNew("$$$$");DocPutS(d,s);
  if(d->head.next->type_u8==DOCT_TEXT&&StrCmp(d->head.next->tag,"$$")==0&&StrCmp(s,"$$$$")==0)mask|=2;
  Free(s);DocDel(d);
  d=DocNew("C:/Output.DD",Fs);s=StrNew("a\r\nb\tc");DocPutS(d,s);e=d->head.next;
  if(e->type_u8==DOCT_TEXT&&e->next->type_u8==DOCT_NEW_LINE&&e->next->next->next->type_u8==DOCT_TAB&&StrCmp(s,"a\r\nb\tc")==0)mask|=4;
  Free(s);DocDel(d);
  d=DocNew("C:/Output.DD",Fs);d->flags|=DOCF_PLAIN_TEXT;s=StrNew("$$BT,\"PLAY\",LE=2$$");e=DocPutS(d,s);
  if(!e&&d->head.next->type_u8==DOCT_TEXT&&StrCmp(d->head.next->tag,s)==0)mask|=8;
  Free(s);DocDel(d);
  d=DocNew("C:/Output.DD",Fs);d->flags|=DOCF_PLAIN_TEXT_TABS;s=StrNew("a\tb");DocPutS(d,s);
  if(d->head.next->type_u8==DOCT_TEXT&&StrCmp(d->head.next->tag,s)==0)mask|=16;
  Free(s);DocDel(d);
  d=DocNew("C:/Output.DD",Fs);d->flags|=DOCF_NO_CURSOR;cursor[0]='a';cursor[1]=CH_CURSOR;cursor[2]='b';cursor[3]=0;
  DocPutS(d,cursor);
  if(d->head.next->type_u8==DOCT_TEXT&&StrCmp(d->head.next->tag,"ab")==0&&cursor[1]==CH_CURSOR)mask|=32;
  DocDel(d);
  return mask;
}
