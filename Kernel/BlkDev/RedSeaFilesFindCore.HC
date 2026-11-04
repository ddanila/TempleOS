CDirEntry *RedSeaFilesFind(U8 *files_find_mask,I64 fuf_flags,
	CDirEntry *parent=NULL)
{
  CDrv *dv=Fs->cur_dv;
  CDirEntry *buf,*buf2,*ptr,*res=NULL,*tmpde;
  I64 ch,cur_dir_clus;
  if (fuf_flags&~FUG_FILES_FIND)
    throw('FUF');
  try {
    DrvLock(dv);
    cur_dir_clus=Name2DirClus(dv,Fs->cur_dir);
    buf2=MAlloc(BLK_SIZE);
    BlkRead(dv,buf2,cur_dir_clus,1);

    ptr=buf2(U8 *)-offset(CDirEntry.start);
    buf=MAlloc(ptr->size);
    BlkRead(dv,buf,cur_dir_clus,ptr->size>>BLK_SIZE_BITS);
    Free(buf2);

    ptr=buf(U8 *)-offset(CDirEntry.start);
    *ptr->name='.';
    ptr->name[1]=0;
    ptr(U8 *)+=CDIR_SIZE;
    ptr->clus=Name2ParentDirClus(dv,Fs->cur_dir);
    ptr(U8 *)-=CDIR_SIZE;
    while (TRUE) {
      if (!(ch=*ptr->name))
	break;
      else if (!(ptr->attr & RS_ATTR_DELETED)) {
	tmpde=CAlloc(sizeof(CDirEntry));
	MemCpy(&tmpde->start,&ptr->start,CDIR_SIZE);
	tmpde->parent=parent;
	if (Bt(&fuf_flags,FUf_RECURSE) && tmpde->attr&RS_ATTR_DIR &&
	      *tmpde->name!='.') {
	  tmpde->next=res;
	  res=tmpde;
	  tmpde->full_name=DirNameAbs(tmpde->name);
	  DrvUnlock(dv);
	  if (Cd(tmpde->name)) {
	    tmpde->sub=RedSeaFilesFind(files_find_mask,fuf_flags,tmpde);
	    Cd("..");
	  }
	  DrvLock(dv);
	} else {
	  tmpde->full_name=FileNameAbs(tmpde->name);
	  if ((tmpde->attr&RS_ATTR_DIR ||
		!Bt(&fuf_flags,FUf_JUST_DIRS)) &&
		!(Bt(&fuf_flags,FUf_RECURSE) && *tmpde->name=='.' &&
		tmpde->attr&RS_ATTR_DIR) &&
		FilesFindMatch(tmpde->full_name,files_find_mask,fuf_flags)) {
	    tmpde->next=res;
	    res=tmpde;
	  } else
	    DirEntryDel(tmpde);
	}
      }
      ptr(U8 *)+=CDIR_SIZE;
    }
    Free(buf);
    DrvUnlock(dv);
  } catch
    DrvUnlock(dv);
  return res;
}
