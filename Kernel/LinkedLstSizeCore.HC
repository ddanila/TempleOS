I64 LinkedLstSize(U8 **_lst)
{//Mem size of all nodes in linked-list.
  I64 res=0;
  while (_lst) {
    res+=MSize2(_lst);
    _lst=*_lst;
  }
  return res;
}
