I64 ExeFile2(U8 *name,I64 ccf_flags=0)
{//throws exceptions
  I64 res;
  U8 *name2=ExtDft(name,"HC.Z"),*st=MStrPrint("#include \"%s\";",name2);
  res=ExePutS2(st,name,ccf_flags);
  Free(st);
  Free(name2);
  return res;
}
