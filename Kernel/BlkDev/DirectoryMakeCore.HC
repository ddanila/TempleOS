Bool DirMk(U8 *filename,I64 entry_cnt=0)
{//Make directory. $LK,"Cd",A="MN:Cd"$() can also make directories.
//entry_cnt is for preallocating dir blks, leave it zero if you like.
  U8 *name;
  CDirContext *dirc;
  Bool res=FALSE;
  if (FileFind(filename,,FUF_JUST_DIRS))
    return FALSE;
  if (dirc=DirContextNew(filename)) {
    if (*dirc->mask) {
      if (!FileNameChk(dirc->mask))
	PrintErr("Invalid FileName: \"%s\".\n",dirc->mask);
      else {
	"Make Directory:%s\n",filename;
	name=MStrUtil(dirc->mask,
	      SUF_REM_LEADING|SUF_REM_TRAILING|SUF_REM_CTRL_CHARS);
	switch (dirc->dv->fs_type) {
	  case FSt_REDSEA:
	    res=RedSeaMkDir(dirc->dv,Fs->cur_dir,name,entry_cnt);
	    break;
	  case FSt_FAT32:
	    res=FAT32MkDir(dirc->dv,Fs->cur_dir,name,entry_cnt);
	    break;
	  default:
	    PrintErr("File System Not Supported\n");
	}
	Free(name);
      }
    }
    DirContextDel(dirc);
  }
  return res;
}
