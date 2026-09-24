I64 doc_basic_boundary_size;
U8 doc_basic_boundary_data[12];

U0 DocBasicBoundaryRemember(U8 *text,I64 size)
{
  I64 i;
  doc_basic_boundary_size=size;
  for(i=0;i<12;i++) doc_basic_boundary_data[i]=text[i];
}

Bool DocBasicBoundaryAt(U8 *text,I64 size,U8 *plain,I64 plain_size,I64 cursor)
{
  I64 i,j=0;
  if(size!=plain_size+1) return FALSE;
  for(i=0;i<size;i++) {
    if(i==cursor) { if(text[i]!=CH_CURSOR) return FALSE; }
    else if(text[i]!=plain[j++]) return FALSE;
  }
  return !text[size];
}

I64 DocBasicBoundaryCheck(U0 (*put_key)(CDoc *doc,I64 ch,I64 sc),
      U8 *(*save)(CDoc *doc,I64 *size),Bool recalc)
{
  CDoc *doc=DocNew("C:/BasicBoundary.DD",Fs);
  U8 *text;
  I64 size,result=13;
  text=(*save)(doc,&size); DocBasicBoundaryRemember(text,size);
  if(size || text[0]) { result=-1; goto boundary_done; }
  Free(text);
  (*put_key)(doc,0,SC_CURSOR_UP); (*put_key)(doc,0,SC_CURSOR_DOWN);
  (*put_key)(doc,CH_BACKSPACE,0); (*put_key)(doc,0,SC_DELETE);
  (*put_key)(doc,0,SC_HOME); (*put_key)(doc,0,SC_END);
  text=(*save)(doc,&size); DocBasicBoundaryRemember(text,size);
  if(size || text[0]) { result=-2; goto boundary_done; }
  Free(text);
  (*put_key)(doc,'a',0); (*put_key)(doc,'\n',0); (*put_key)(doc,'\n',0);
  (*put_key)(doc,'b',0); (*put_key)(doc,0,SC_HOME);
  if(recalc) DocRecalc(doc); (*put_key)(doc,0,SC_CURSOR_DOWN);
  text=(*save)(doc,&size); DocBasicBoundaryRemember(text,size);
  if(!DocBasicBoundaryAt(text,size,"a\n\nb",4,2))
    { result=-3; goto boundary_done; }
  Free(text); doc->flags|=DOCF_NO_CURSOR; text=(*save)(doc,&size);
  DocBasicBoundaryRemember(text,size);
  if(size!=4 || StrCmp(text,"a\n\nb")) { result=-4; goto boundary_done; }
  Free(text); doc->flags&=~DOCF_NO_CURSOR;
  if(recalc) DocRecalc(doc); (*put_key)(doc,0,SC_CURSOR_DOWN);
  text=(*save)(doc,&size); DocBasicBoundaryRemember(text,size);
  if(!DocBasicBoundaryAt(text,size,"a\n\nb",4,3))
    { result=-5; goto boundary_done; }
  Free(text); if(recalc) DocRecalc(doc); (*put_key)(doc,0,SC_CURSOR_UP);
  text=(*save)(doc,&size); DocBasicBoundaryRemember(text,size);
  if(!DocBasicBoundaryAt(text,size,"a\n\nb",4,2))
    { result=-6; goto boundary_done; }
  Free(text); (*put_key)(doc,'X',0);
  text=(*save)(doc,&size); DocBasicBoundaryRemember(text,size);
  if(!DocBasicBoundaryAt(text,size,"a\nX\nb",5,3))
    { result=-7; goto boundary_done; }
  Free(text); (*put_key)(doc,CH_BACKSPACE,0);
  text=(*save)(doc,&size); DocBasicBoundaryRemember(text,size);
  if(!DocBasicBoundaryAt(text,size,"a\n\nb",4,2))
    { result=-8; goto boundary_done; }
  Free(text); (*put_key)(doc,0,SC_DELETE);
  text=(*save)(doc,&size); DocBasicBoundaryRemember(text,size);
  if(!DocBasicBoundaryAt(text,size,"a\nb",3,2))
    { result=-9; goto boundary_done; }
  Free(text); (*put_key)(doc,CH_BACKSPACE,0);
  text=(*save)(doc,&size); DocBasicBoundaryRemember(text,size);
  if(!DocBasicBoundaryAt(text,size,"ab",2,1))
    { result=-10; goto boundary_done; }
  Free(text); (*put_key)(doc,0,SC_HOME); (*put_key)(doc,CH_BACKSPACE,0);
  text=(*save)(doc,&size); DocBasicBoundaryRemember(text,size);
  if(size!=2 || StrCmp(text,"ab")) { result=-11; goto boundary_done; }
  Free(text); (*put_key)(doc,0,SC_END); (*put_key)(doc,0,SC_DELETE);
  text=(*save)(doc,&size); DocBasicBoundaryRemember(text,size);
  if(!DocBasicBoundaryAt(text,size,"ab",2,2)) result=-12;
boundary_done:
  Free(text); DocDel(doc);
  return result;
}
