public Bool Plain(U8 *filename,I64 edf_dof_flags=0)
{//Edit document in plain text mode, so dollar signs are not special.
  Bool res;
  U8 *st=MStrPrint("PI:%s",filename);
  res=Ed(st,edf_dof_flags);
  Free(st);
  return res;
}
