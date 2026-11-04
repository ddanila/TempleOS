CDirEntry *FAT32FilesFind(U8 *files_find_mask,
	I64 fuf_flags,CDirEntry *parent=NULL,I64 *_dir_size=NULL)
{
  CDrv *dv=Fs->cur_dv;
  CFAT32DirEntry *buf;
  I64 attr,xsum=0,dir_size=0,sub_dir_size,
	cur_dir_clus,cur_dir_entry,entries_per_clus;
  U8 ch;
  CDirEntry *res=NULL,*tmpde,long_name;
  if (fuf_flags&~FUG_FILES_FIND)
    throw('FUF');
  try {
    MemSet(&long_name,0,sizeof(CDirEntry));
    DrvLock(dv);
    cur_dir_clus=Name2DirClus(dv,Fs->cur_dir);
    buf=MAlloc(BLK_SIZE*dv->spc);
    entries_per_clus=dv->spc<<FAT32_ENTRIES_BITS;
    ClusRead(dv,buf,cur_dir_clus,1);
    dir_size+=dv->spc*BLK_SIZE;
    cur_dir_entry=0;
    while (ch=*buf[cur_dir_entry].name) {
      attr=buf[cur_dir_entry].attr;
      if (ch!=0xE5) {
	if (attr&RS_ATTR_LONG_NAME_MASK==RS_ATTR_LONG_NAME)
	  DirLongNameFill(&long_name,&buf[cur_dir_entry],&xsum);
	else {
	  if (!(attr&RS_ATTR_VOL_ID)) {
	    tmpde=MAlloc(sizeof(CDirEntry));
	    if (xsum==FATNameXSum(buf[cur_dir_entry].name))
	      MemCpy(tmpde,&long_name,sizeof(CDirEntry));
	    else
	      MemSet(tmpde,0,sizeof(CDirEntry));
	    if (FAT32CDirFill(tmpde,&buf[cur_dir_entry],
		  dv->fat32_local_time_offset)) {
	      tmpde->parent=parent;
	      if (Bt(&fuf_flags,FUf_RECURSE) && attr&RS_ATTR_DIR &&
		    *tmpde->name!='.') {
		tmpde->next=res;
		res=tmpde;
		tmpde->full_name=DirNameAbs(tmpde->name);
		DrvUnlock(dv);
		if (Cd(tmpde->name)) {
		  tmpde->sub=FAT32FilesFind(files_find_mask,fuf_flags,
			tmpde,&sub_dir_size);
		  tmpde->size=sub_dir_size;
		  Cd("..");
		}
		DrvLock(dv);
	      } else {
		tmpde->full_name=FileNameAbs(tmpde->name);
		if ((attr&RS_ATTR_DIR || !Bt(&fuf_flags,FUf_JUST_DIRS)) &&
		      !(Bt(&fuf_flags,FUf_RECURSE) &&
		      *tmpde->name=='.' && attr&RS_ATTR_DIR) &&
		      FilesFindMatch(tmpde->full_name,files_find_mask,
		      fuf_flags)) {
		  tmpde->next=res;
		  res=tmpde;
		} else
		  DirEntryDel(tmpde);
	      }
	    } else
	      DirEntryDel(tmpde);
	  }
	  MemSet(&long_name,0,sizeof(CDirEntry));
	}
      } else
	MemSet(&long_name,0,sizeof(CDirEntry));
      if (++cur_dir_entry==entries_per_clus) {
	cur_dir_clus=ClusNumNext(dv,cur_dir_clus);
	if (cur_dir_clus==INVALID_CLUS)
	  break;
	else {
	  ClusRead(dv,buf,cur_dir_clus,1);
	  dir_size+=dv->spc*BLK_SIZE;
	  cur_dir_entry=0;
	}
      }
    }
    Free(buf);
    DrvUnlock(dv);
  } catch
    DrvUnlock(dv);
  if (_dir_size)
    *_dir_size=dir_size;
  return res;
}
