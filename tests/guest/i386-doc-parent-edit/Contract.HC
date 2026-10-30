I64 DocParentEditContract()
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  U8 *base="C:/EdParent2",*sub="C:/EdParent2/Sub",*parent="C:/EdParent2/Exact.DD";
  U8 *child="C:/EdParent2/Sub/Exact.DD",*link="FL:C:/EdParent2/Sub/Exact.DD,2";
  U8 *data,*initial="alpha\nbeta\n";I64 mask=0,size=0;Bool result;
  if(DirMk(base) && DirMk(sub) && FileWrite(parent,initial,StrLen(initial))>0)mask|=1;
  FlushMsgs;Msg(MSG_KEY_DOWN,'Z',0);Msg(MSG_KEY_DOWN,CH_ESC,0);
  result=Ed(link);
  if(result)mask|=2;
  data=FileRead(child,&size);
  if(data && size && StrMatch("alpha\nZ",data) && StrMatch("beta",data))mask|=4;
  Free(data);data=FileRead(parent,&size);
  if(data && size==StrLen(initial) && !StrCmp(data,initial))mask|=8;
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=16;
  Free(data);FlushMsgs;return mask;
}
