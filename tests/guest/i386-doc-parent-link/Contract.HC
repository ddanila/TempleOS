I64 DocParentLinkContract(I64 mode)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  U8 *base="C:/EdParent",*sub="C:/EdParent/Sub",*name,*link,*data,*initial="alpha\nbeta\n";
  I64 mask=0,size=0;Bool result;
  if((DirMk(base)||FileFind(base,,FUF_JUST_DIRS)) &&
     (DirMk(sub)||FileFind(sub,,FUF_JUST_DIRS)))mask|=1;
  if(mode)name="C:/EdParent/Alt.DD.Z";else name="C:/EdParent/Exact.DD";
  if(FileWrite(name,initial,StrLen(initial))>0)mask|=2;
  if(mode)link="FL:C:/EdParent/Sub/Alt.DD,2";
  else link="FL:C:/EdParent/Sub/Exact.DD,2";
  result=Ed(link,EDF_BAIL);
  if(result)mask|=4;
  data=FileRead(name,&size);
  if(data && size==StrLen(initial) && !StrCmp(data,initial))mask|=8;
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=16;
  Free(data);return mask;
}
