U0 LinkedLstDel(U8 **_lst)
{//Free entire linked-list.
  U8 **tmpl;
  while (_lst) {
    tmpl=*_lst;
    Free(_lst);
    _lst=tmpl;
  }
}

U8 *LinkedLstCopy(U8 **_lst,CTask *mem_task=NULL)
{//MAlloc ident copy of entire linked-list.
  U8 *res=NULL,**tmpl=&res;
  while (_lst) {
    tmpl=*tmpl=MAllocIdent(_lst,mem_task);
    _lst=*_lst;
  }
  return res;
}

