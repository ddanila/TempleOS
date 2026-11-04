Bool Cd(U8 *dirname=NULL,Bool make_dirs=FALSE)
{//Change directory. Optionally, make directories, too.
  I64 maxlen,cur_dir_clus=0;
  U8 *chg_to_buf,*new_cur_dir,*buf;
  CDrv *dv;
  Bool res=TRUE;
  if (!dirname)
    dirname="~";
  else if (!*dirname)
    return TRUE;
  if (dirname[1]==':') {
    if (*dirname==':') {
      if (Fs->cur_dv!=Let2Drv(':') && !Drv(*dirname))
	return FALSE;
    } else if (Fs->cur_dv!=Let2Drv(*dirname) && !Drv(*dirname))
      return FALSE;
    dirname+=2;
  }
  if (*dirname=='/' || !*dirname || !Fs->cur_dir) {
    Free(Fs->cur_dir);
    Fs->cur_dir=StrNew("/");
    if (*dirname=='/')
      dirname++;
  }
  chg_to_buf=MStrUtil(dirname,
	SUF_REM_LEADING|SUF_REM_TRAILING|SUF_REM_CTRL_CHARS);
  maxlen=StrLen(Fs->cur_dir)+1+StrLen(chg_to_buf)+1;
  new_cur_dir=MAlloc(maxlen);
  buf=MAlloc(maxlen);
  StrCpy(new_cur_dir,Fs->cur_dir);
  while (*chg_to_buf && res) {
    StrFirstRem(chg_to_buf,"/",buf);
    if (!*buf)
      StrCpy(new_cur_dir,"/");
    else if (!StrCmp(buf,"..")) {
      StrLastRem(new_cur_dir,"/");
      if (!*new_cur_dir)
	StrCpy(new_cur_dir,"/");
    } else if (!StrCmp(buf,"~")) {
      Free(new_cur_dir);
      new_cur_dir=MAlloc(StrLen(blkdev.home_dir+2)+1+StrLen(chg_to_buf)+1);
      StrCpy(new_cur_dir,blkdev.home_dir+2);
      if (Fs->cur_dv!=Let2Drv('~') && !Drv('~'))
	return FALSE;
    } else if (StrCmp(buf,".") && *buf) {
      dv=Fs->cur_dv;
      cur_dir_clus=Name2DirClus(dv,new_cur_dir);
      switch (dv->fs_type) {
	case FSt_REDSEA:
	  res=RedSeaCd(buf,cur_dir_clus);
	  break;
	case FSt_FAT32:
	  res=FAT32Cd(buf,cur_dir_clus);
	  break;
	default:
	  PrintErr("File System Not Supported\n");
	  res=FALSE;
      }
      if (!res && make_dirs) {
	Free(Fs->cur_dir);
	Fs->cur_dir=StrNew(new_cur_dir);
	res=DirMk(buf);
      }
      if (res) {
	if (StrCmp(new_cur_dir,"/"))
	  CatPrint(new_cur_dir,"/");
	CatPrint(new_cur_dir,buf);
      }
    }
  }
  Free(Fs->cur_dir);
  Fs->cur_dir=StrNew(new_cur_dir);
  Free(buf);
  Free(chg_to_buf);
  Free(new_cur_dir);
  return res;
}
