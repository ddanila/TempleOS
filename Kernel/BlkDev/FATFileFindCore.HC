Bool FAT32FileFind(CDrv *dv,I64 cur_dir_clus,
	U8 *name,CDirEntry *_res,I64 fuf_flags=0)
{//$LK,"FUF_JUST_DIRS",A="MN:FUF_JUST_DIRS"$, $LK,"FUF_JUST_FILES",A="MN:FUF_JUST_FILES"$
  Bool res=FALSE,unlock;
  CFAT32DirEntry *buf;
  I64 xsum=0,attr,cur_dir_entry,entries_per_clus;
  U8 dname[CDIR_FILENAME_LEN],short_name[16],ch;
  CDirEntry long_name;
  if (fuf_flags&~FUG_FILE_FIND)
    throw('FUF');
  MemSet(_res,0,sizeof(CDirEntry));
  MemSet(&long_name,0,sizeof(CDirEntry));
  DrvChk(dv);
  if (dv->fs_type!=FSt_FAT32)
    PrintErr("Not FAT32 Drv\n");
  else if (!CFileNameTo(dname,name))
    PrintErr("Invalid FileName: \"%s\".\n",name);
  else
    try {
      unlock=DrvLock(dv);
      buf=MAlloc(BLK_SIZE*dv->spc);
      entries_per_clus=dv->spc<<FAT32_ENTRIES_BITS;
      ClusRead(dv,buf,cur_dir_clus,1);
      cur_dir_entry=0;
      while (ch=*buf[cur_dir_entry].name) {
	attr=buf[cur_dir_entry].attr;
	if (ch!=0xE5) {
	  if (attr&RS_ATTR_LONG_NAME_MASK==RS_ATTR_LONG_NAME)
	    DirLongNameFill(&long_name,&buf[cur_dir_entry],&xsum);
	  else {
	    if (!(attr&RS_ATTR_VOL_ID)) {
	      if (xsum==FATNameXSum(buf[cur_dir_entry].name))
		MemCpy(_res,&long_name,sizeof(CDirEntry));
	      else
		MemSet(_res,0,sizeof(CDirEntry));
	      FATFromName(short_name,buf[cur_dir_entry].name);
	      if (!(fuf_flags&FUF_JUST_DIRS && !(attr & RS_ATTR_DIR)) &&
		    !(fuf_flags&FUF_JUST_FILES && attr & RS_ATTR_DIR) &&
		    FAT32CDirFill(_res,&buf[cur_dir_entry],
		    dv->fat32_local_time_offset) &&
		    (!StrCmp(dname,_res->name) || !StrICmp(dname,short_name))) {
		res=TRUE;
		goto fff_done;
	      }
	    }
	    MemSet(&long_name,0,sizeof(CDirEntry));
	  }
	} else
	  MemSet(&long_name,0,sizeof(CDirEntry));
	if (++cur_dir_entry==entries_per_clus) {
	  cur_dir_clus=ClusNumNext(dv,cur_dir_clus);
	  if (!(0<cur_dir_clus<0x0FFFFFF8))
	    break;
	  else {
	    ClusRead(dv,buf,cur_dir_clus,1);
	    cur_dir_entry=0;
	  }
	}
      }
      MemSet(_res,0,sizeof(CDirEntry));
fff_done:
      Free(buf);
      if (unlock)
	DrvUnlock(dv);
    } catch
      if (unlock)
	DrvUnlock(dv);
  return res;
}

