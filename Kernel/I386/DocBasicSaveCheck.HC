I64 DocBasicSaveCheck(U8 *(*save)(CDoc *doc,I64 *size))
{
  CDoc *doc=DocNew("C:/BasicSave.DD",Fs);
  U8 *text;
  I64 size=0,result=5;
  DocPutKey(doc,'a'); DocPutKey(doc,'b'); DocPutKey(doc,'c');
  DocPutKey(doc,0,0x4B); DocPutKey(doc,0,0x4B); //SC_CURSOR_LEFT
  DocPutKey(doc,'Z');
  text=(*save)(doc,&size);
  if(!text) result=-1;
  else if(text[0]!='a' || text[1]!='Z' || text[2]!=5 || //CH_CURSOR
      text[3]!='b' || text[4]!='c' || text[5]) result=-2;
  else if(size!=5) result=-3;
  Free(text); DocDel(doc);
  return result;
}
