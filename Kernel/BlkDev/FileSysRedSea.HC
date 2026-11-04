// See $LK,"RedSea File System",A="FI:::/Doc/RedSea.DD"$

#include "/Kernel/BlkDev/RedSeaFreeFreeListCore.HC"

#include "/Kernel/BlkDev/RedSeaAllocationCore.HC"

#include "/Kernel/BlkDev/RedSeaMediaCore.HC"

#include "/Kernel/BlkDev/RedSeaFileFindCore.HC"

U8 *RedSeaFileRead(CDrv *dv,U8 *cur_dir,U8 *filename,I64 *_size,I64 *_attr)
{
  U8 *buf=NULL;
  CDirEntry de;
  I64 c,blk_cnt,cur_dir_clus;
  DrvChk(dv);
  *_size=0;
  *_attr=0;
  if (dv->fs_type!=FSt_REDSEA)
    PrintErr("Not RedSea Drv\n");
  else
    try {
      DrvLock(dv);
      cur_dir_clus=Name2DirClus(dv,cur_dir);
      if (RedSeaFileFind(dv,cur_dir_clus,filename,&de,FUF_JUST_FILES)) {
	blk_cnt=(de.size+BLK_SIZE-1)>>BLK_SIZE_BITS;
	buf=MAlloc(blk_cnt<<BLK_SIZE_BITS+1);
	c=de.clus;
	c=BlkRead(dv,buf,c,blk_cnt);
	buf[de.size]=0; //Terminate
	*_size=de.size;
	*_attr=FileAttr(de.name,de.attr);
      }
      DrvUnlock(dv);
    } catch
      DrvUnlock(dv);
  return buf;
}

Bool RedSeaCd(U8 *name,I64 cur_dir_clus)
{
  CDirEntry de;
  if (Fs->cur_dv->fs_type!=FSt_REDSEA)
    PrintErr("Not RedSea Drv\n");
  else if (RedSeaFileFind(Fs->cur_dv,cur_dir_clus,name,&de,FUF_JUST_DIRS))
    return TRUE;
  else
    PrintErr("File not found: \"%s\".\n",name);
  return FALSE;
}


#include "/Kernel/BlkDev/RedSeaDirectoryMutationCore.HC"

I64 RedSeaFileWrite(CDrv *dv,U8 *cur_dir,U8 *name,U8 *buf,I64 size,
	CDate cdt,I64 attr)
{
  CDirEntry de;
  I64 c=0,blk_cnt;
  MemSet(&de,0,sizeof(CDirEntry));
  if (size<0) size=0;
  if (dv->fs_type!=FSt_REDSEA)
    PrintErr("Not RedSea Drv\n");
  else if (!CFileNameTo(de.name,name))
    PrintErr("Invalid FileName: \"%s\".\n",name);
  else {
    RedSeaFilesDel(dv,cur_dir,de.name,0,FALSE,FALSE);
    de.size=size;
    if (blk_cnt=(size+BLK_SIZE-1)>>BLK_SIZE_BITS)
      c=ClusAlloc(dv,0,blk_cnt,TRUE); //Always contiguous
    else
      c=INVALID_CLUS;
    de.clus=c;
    de.attr=attr|RS_ATTR_CONTIGUOUS;
    de.datetime=cdt;
    if (blk_cnt)
      BlkWrite(dv,buf,c,blk_cnt);
    RedSeaDirNew(dv,cur_dir,&de,TRUE);
  }
  return c;
}

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

Bool RedSeaMkDir(CDrv *dv,U8 *cur_dir,U8 *name,I64 entry_cnt)
{//entry_cnt is for preallocating dir blks.
  I64	c,cur_dir_clus=Name2DirClus(dv,cur_dir),
	size=CeilU64((entry_cnt+3)<<6,BLK_SIZE);
#assert CDIR_SIZE==64
  U8 *buf=CAlloc(size);
  CDirEntry *d_native=buf-offset(CDirEntry.start);
  Bool unlock_break;
  try {
    unlock_break=BreakLock;
    c=FileWrite(name,buf,size,0,RS_ATTR_DIR);
    d_native->attr=RS_ATTR_DIR|RS_ATTR_CONTIGUOUS;
    StrCpy(d_native->name,name);
    d_native->clus=c;
    d_native->size=size;
    d_native->datetime=Now;
    d_native(U8 *)+=CDIR_SIZE;

    d_native->attr=RS_ATTR_DIR|RS_ATTR_CONTIGUOUS;
    *d_native->name='.';
    d_native->name[1]='.';
    d_native->name[2]=0;
    d_native->clus=cur_dir_clus;
    d_native->size=0;
    d_native->datetime=Now;
    BlkWrite(dv,buf,c,1);
    Free(buf);
    if (unlock_break)
      BreakUnlock;
  } catch
    if (unlock_break)
      BreakUnlock;
  return TRUE;
}
