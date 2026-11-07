CDirEntry *Cd2DirEntry(CDirEntry *tmpde,U8 *abs_name)
{
  I64 i;
  while (tmpde) {
    i=StrLen(tmpde->full_name);
    if (StrNCmp(tmpde->full_name,abs_name,i)||
	  i && tmpde->full_name[i-1]!='/' && abs_name[i] && abs_name[i]!='/')
      tmpde=tmpde->next;
    else
      if (StrLen(abs_name)==i)
	return tmpde;
      else
	return Cd2DirEntry(tmpde->sub,abs_name);
  }
  return NULL;
}
