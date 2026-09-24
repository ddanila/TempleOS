I64 doc_basic_navigation_size;
U8 doc_basic_navigation_data[8];
U0 DocBasicNavigationRemember(U8 *text,I64 size)
{
  I64 i;
  doc_basic_navigation_size=size;
  for(i=0;i<8;i++) doc_basic_navigation_data[i]=text[i];
}

I64 DocBasicNavigationCheck(U0 (*put_key)(CDoc *doc,I64 ch,I64 sc),
      U8 *(*save)(CDoc *doc,I64 *size))
{
  CDoc *doc=DocNew("C:/BasicNavigation.DD",Fs);
  U8 *text;
  I64 size,result=8;
  (*put_key)(doc,'a',0); (*put_key)(doc,'b',0); (*put_key)(doc,'c',0);
  (*put_key)(doc,0,SC_HOME);
  text=(*save)(doc,&size);
  DocBasicNavigationRemember(text,size);
  if(size!=3 || text[0]!='a' || text[1]!='b' || text[2]!='c' || text[3])
    { result=-1; goto nav_done; }
  Free(text);
  (*put_key)(doc,0,SC_CURSOR_RIGHT);
  text=(*save)(doc,&size);
  DocBasicNavigationRemember(text,size);
  if(size!=4 || text[0]!='a' || text[1]!=CH_CURSOR || text[2]!='b' ||
      text[3]!='c' || text[4]) { result=-2; goto nav_done; }
  Free(text);
  (*put_key)(doc,0,SC_DELETE);
  text=(*save)(doc,&size);
  DocBasicNavigationRemember(text,size);
  if(size!=3 || text[0]!='a' || text[1]!=CH_CURSOR || text[2]!='c' ||
      text[3]) { result=-3; goto nav_done; }
  Free(text);
  (*put_key)(doc,'\t',SC_TAB);
  text=(*save)(doc,&size);
  DocBasicNavigationRemember(text,size);
  if(size!=4 || text[0]!='a' || text[1]!='\t' || text[2]!=CH_CURSOR ||
      text[3]!='c' || text[4]) { result=-4; goto nav_done; }
  Free(text);
  (*put_key)(doc,0,SC_END);
  text=(*save)(doc,&size);
  DocBasicNavigationRemember(text,size);
  if(size!=4 || text[0]!='a' || text[1]!='\t' || text[2]!='c' ||
      text[3]!=CH_CURSOR || text[4]) { result=-5; goto nav_done; }
  Free(text);
  (*put_key)(doc,0,SC_HOME); (*put_key)(doc,0,SC_CURSOR_RIGHT);
  text=(*save)(doc,&size);
  DocBasicNavigationRemember(text,size);
  if(size!=4 || text[0]!='a' || text[1]!=CH_CURSOR || text[2]!='\t' ||
      text[3]!='c' || text[4]) { result=-6; goto nav_done; }
  Free(text);
  (*put_key)(doc,0,SC_CURSOR_RIGHT);
  text=(*save)(doc,&size);
  DocBasicNavigationRemember(text,size);
  if(size!=4 || text[0]!='a' || text[1]!='\t' || text[2]!=CH_CURSOR ||
      text[3]!='c' || text[4]) { result=-7; goto nav_done; }
nav_done:
  Free(text); DocDel(doc);
  return result;
}
