Bool DocBasicTextEqu(CDoc *doc,U8 *expected)
{
  CDocEntry *entry=doc->head.next;
  U8 *text;
  while(entry!=doc) {
    if(entry->type_u8==DOCT_TEXT) {
      text=entry->tag;
      while(*text) if(*text++!=*expected++) return FALSE;
    }
    entry=entry->next;
  }
  return !*expected;
}
I64 DocBasicEditCheck(U0 (*put_key)(CDoc *doc,I64 ch,I64 sc))
{
  CDoc *doc=DocNew("C:/BasicEdit.DD",Fs);
  I64 result=5;
  (*put_key)(doc,'a',0); (*put_key)(doc,'b',0); (*put_key)(doc,'c',0);
  if(!DocBasicTextEqu(doc,"abc")) result=-1;
  (*put_key)(doc,0,0x4B); (*put_key)(doc,0,0x4B); //SC_CURSOR_LEFT
  (*put_key)(doc,'X',0);
  if(!DocBasicTextEqu(doc,"aXbc")) result=-2;
  (*put_key)(doc,8,0); //CH_BACKSPACE
  if(!DocBasicTextEqu(doc,"abc")) result=-3;
  (*put_key)(doc,'Z',0);
  if(!DocBasicTextEqu(doc,"aZbc")) result=-4;
  DocDel(doc);
  return result;
}
