I64 DocBasicMultilineCheck(U0 (*put_key)(CDoc *doc,I64 ch,I64 sc),
      U8 *(*save)(CDoc *doc,I64 *size))
{
  CDoc *doc=DocNew("C:/BasicMultiline.DD",Fs);
  U8 *text;
  I64 size,result=7;
  (*put_key)(doc,'a',0); (*put_key)(doc,'b',0); (*put_key)(doc,'\n',0);
  (*put_key)(doc,'c',0); (*put_key)(doc,'d',0);
  text=(*save)(doc,&size);
  if(size!=6 || text[0]!='a' || text[1]!='b' || text[2]!='\n' ||
      text[3]!='c' || text[4]!='d' || text[5]!=CH_CURSOR) result=-1;
  Free(text);
  (*put_key)(doc,0,SC_CURSOR_LEFT); (*put_key)(doc,0,SC_CURSOR_LEFT);
  (*put_key)(doc,'X',0);
  text=(*save)(doc,&size);
  if(size!=7 || text[3]!='X' || text[4]!=CH_CURSOR) result=-2;
  Free(text);
  (*put_key)(doc,CH_BACKSPACE,0);
  text=(*save)(doc,&size);
  if(size!=6 || text[3]!=CH_CURSOR || text[4]!='c') result=-3;
  Free(text);
  (*put_key)(doc,CH_BACKSPACE,0);
  text=(*save)(doc,&size);
  if(size!=5 || text[0]!='a' || text[1]!='b' || text[2]!=CH_CURSOR ||
      text[3]!='c' || text[4]!='d') result=-4;
  Free(text);
  (*put_key)(doc,'Z',0);
  text=(*save)(doc,&size);
  if(size!=6 || text[0]!='a' || text[1]!='b' || text[2]!='Z' ||
      text[3]!=CH_CURSOR || text[4]!='c' || text[5]!='d') result=-5;
  Free(text); DocDel(doc);
  return result;
}
