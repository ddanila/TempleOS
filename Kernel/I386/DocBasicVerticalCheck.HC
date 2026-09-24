I64 doc_basic_vertical_size;
U8 doc_basic_vertical_data[24];

U0 DocBasicVerticalRemember(U8 *text,I64 size)
{
  I64 i;
  doc_basic_vertical_size=size;
  for(i=0;i<24;i++) doc_basic_vertical_data[i]=text[i];
}

Bool DocBasicVerticalAt(U8 *text,I64 size,I64 cursor)
{
  I64 i,j;
  U8 *expected="abcde\nxy\n12345";
  if(size!=15) return FALSE;
  for(i=0;i<15;i++) {
    if(i==cursor) {
      if(text[i]!=CH_CURSOR) return FALSE;
    } else {
      j=i; if(i>cursor) j--;
      if(text[i]!=expected[j]) return FALSE;
    }
  }
  return !text[15];
}

I64 DocBasicVerticalCheck(U0 (*put_key)(CDoc *doc,I64 ch,I64 sc),
      U8 *(*save)(CDoc *doc,I64 *size),Bool recalc)
{
  CDoc *doc=DocNew("C:/BasicVertical.DD",Fs);
  U8 *text;
  I64 size,result=8;
  (*put_key)(doc,'a',0); (*put_key)(doc,'b',0); (*put_key)(doc,'c',0);
  (*put_key)(doc,'d',0); (*put_key)(doc,'e',0); (*put_key)(doc,'\n',0);
  (*put_key)(doc,'x',0); (*put_key)(doc,'y',0); (*put_key)(doc,'\n',0);
  (*put_key)(doc,'1',0); (*put_key)(doc,'2',0); (*put_key)(doc,'3',0);
  (*put_key)(doc,'4',0); (*put_key)(doc,'5',0);
  (*put_key)(doc,0,SC_HOME); (*put_key)(doc,0,SC_CURSOR_RIGHT);
  (*put_key)(doc,0,SC_CURSOR_RIGHT); if(recalc) DocRecalc(doc);
  (*put_key)(doc,0,SC_CURSOR_DOWN);
  text=(*save)(doc,&size); DocBasicVerticalRemember(text,size);
  if(!DocBasicVerticalAt(text,size,8)) { result=-1; goto vertical_done; }
  Free(text); if(recalc) DocRecalc(doc); (*put_key)(doc,0,SC_CURSOR_DOWN);
  text=(*save)(doc,&size); DocBasicVerticalRemember(text,size);
  if(!DocBasicVerticalAt(text,size,11)) { result=-2; goto vertical_done; }
  Free(text); if(recalc) DocRecalc(doc); (*put_key)(doc,0,SC_CURSOR_UP);
  text=(*save)(doc,&size); DocBasicVerticalRemember(text,size);
  if(!DocBasicVerticalAt(text,size,8)) { result=-3; goto vertical_done; }
  Free(text); if(recalc) DocRecalc(doc); (*put_key)(doc,0,SC_CURSOR_UP);
  text=(*save)(doc,&size); DocBasicVerticalRemember(text,size);
  if(!DocBasicVerticalAt(text,size,2)) { result=-4; goto vertical_done; }
  Free(text); if(recalc) DocRecalc(doc); (*put_key)(doc,0,SC_CURSOR_UP);
  text=(*save)(doc,&size); DocBasicVerticalRemember(text,size);
  if(!DocBasicVerticalAt(text,size,2)) { result=-5; goto vertical_done; }
  Free(text); (*put_key)(doc,0,SC_END); if(recalc) DocRecalc(doc);
  (*put_key)(doc,0,SC_CURSOR_DOWN);
  text=(*save)(doc,&size); DocBasicVerticalRemember(text,size);
  if(!DocBasicVerticalAt(text,size,14)) { result=-6; goto vertical_done; }
  Free(text); (*put_key)(doc,0,SC_HOME); if(recalc) DocRecalc(doc);
  (*put_key)(doc,0,SC_CURSOR_UP);
  text=(*save)(doc,&size); DocBasicVerticalRemember(text,size);
  if(size!=14 || StrCmp(text,"abcde\nxy\n12345")) result=-7;
vertical_done:
  Free(text); DocDel(doc);
  return result;
}
