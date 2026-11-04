Bool IsDir(U8 *dir_name)
{//Is a str a valid, existing Dir?
  U8 *mask=MStrPrint("%s/*",dir_name);
  Bool res,old_silent=Silent;
  CDirContext *dirc;
  if (dirc=DirContextNew(mask)) {
    DirContextDel(dirc);
    res=TRUE;
  } else
    res=FALSE;
  Free(mask);
  Silent(old_silent);
  return res;
}
