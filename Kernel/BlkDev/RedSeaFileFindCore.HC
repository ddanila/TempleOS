Bool RedSeaFileFind(CDrv *dv,I64 cur_dir_clus,U8 *name,
	CDirEntry *_res,I64 fuf_flags=0)
{//$LK,"FUF_JUST_DIRS",A="MN:FUF_JUST_DIRS"$, $LK,"FUF_JUST_FILES",A="MN:FUF_JUST_FILES"$
  CDirEntry *buf,*buf2,*ptr;
  U8 dname[CDIR_FILENAME_LEN];
  I64 ch;
  Bool res=FALSE,unlock;
  if (fuf_flags&~FUG_FILE_FIND)
    throw('FUF');
  MemSet(_res,0,sizeof(CDirEntry));
  DrvChk(dv);
  if (dv->fs_type!=FSt_REDSEA)
    PrintErr("Not RedSea Drv\n");
  else if (!CFileNameTo(dname,name))
    PrintErr("Invalid FileName: \"%s\".\n",name);
  else
    try {
      unlock=DrvLock(dv);
      buf2=MAlloc(BLK_SIZE);
      BlkRead(dv,buf2,cur_dir_clus,1);

      ptr=buf2(U8 *)-offset(CDirEntry.start);
      buf=MAlloc(ptr->size);
      BlkRead(dv,buf,cur_dir_clus,ptr->size>>BLK_SIZE_BITS);
      Free(buf2);

      ptr=buf(U8 *)-offset(CDirEntry.start);
      *ptr->name='.';
      ptr->name[1]=0;
      while (TRUE) {
	if (!(ch=*ptr->name))
	  break;
	else if (!(ptr->attr & RS_ATTR_DELETED) &&
	      !(fuf_flags&FUF_JUST_DIRS && !(ptr->attr & RS_ATTR_DIR)) &&
	      !(fuf_flags&FUF_JUST_FILES && ptr->attr & RS_ATTR_DIR) &&
	      !StrCmp(dname,ptr->name)) {
	  MemCpy(&_res->attr,&ptr->attr,CDIR_SIZE);
	  res=TRUE;
	  goto rsff_done;
	}
	ptr(U8 *)+=CDIR_SIZE;
      }
rsff_done:
      Free(buf);
      if (unlock)
	DrvUnlock(dv);
    } catch
      if (unlock)
	DrvUnlock(dv);
  return res;
}

