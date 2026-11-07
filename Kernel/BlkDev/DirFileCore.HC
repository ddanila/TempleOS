U8 *DirFile(U8 *dirname,U8 *name=NULL,U8 *_extension=NULL)
{/*Strips file from dirname, scans for file upward until found or
returns default.

("/Kernel/KHashA.HC.Z",NULL,NULL)	returns "D:/Kernel"
("/Kernel",NULL,"PRJ.Z")		returns "D:/Kernel/Kernel.PRJ.Z"
("/Kernel/BlkDev",NULL,"PRJ.Z")		returns "D:/Kernel/Kernel.PRJ.Z"
("/Apps/Psalmody","Load","HC.Z")	returns "D:/Apps/Psalmody/Load.HC.Z"
*/
  U8 *st=DirNameAbs(dirname),*st2,*st3,*res,*dft=NULL,*ext;
  if (_extension && *_extension) {
    if (*_extension=='.')
      ext=StrNew(_extension);
    else
      ext=MStrPrint(".%s",_extension);
  } else
    ext=StrNew("");
  while (StrOcc(st,'/')&&!IsDir(st))
    StrLastRem(st,"/");
  while (StrOcc(st,'/')) {
    st2=StrNew(st);
    st3=StrNew(st);
    StrLastRem(st2,"/",st3);

    if (name)
      res=MStrPrint("%s/%s%s",st,name,ext);
    else {
      if (*ext)
	res=MStrPrint("%s/%s%s",st,st3,ext);
      else
	res=StrNew(st);
    }
    if (!dft)
      dft=StrNew(res);
    if (!*ext && (!name||!*name) || FileFind(res)) {
      Free(st3);
      Free(st2);
      Free(st);
      Free(dft);
      Free(ext);
      return res;
    }
    Free(res); //The retained default is an independent copy.
    Free(st);
    st=st2;
    Free(st3);
  }
  Free(st);
  Free(ext);
  return dft;
}
