I64 ExeFile(U8 *name,I64 ccf_flags=0)
{//JIT Compile and execute a file.
  I64 res;
  U8 *name2=ExtDft(name,"HC.Z"),
	*st=MStrPrint("#include \"%s\";",name2);
  res=ExePutS(st,name,ccf_flags);
  Free(st);
  Free(name2);
  return res;
}
