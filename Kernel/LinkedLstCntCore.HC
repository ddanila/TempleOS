I64 LinkedLstCnt(U8 **_lst)
{//Count of nodes in linked-list.
  I64 res=0;
  while (_lst) {
    res++;
    _lst=*_lst;
  }
  return res;
}

