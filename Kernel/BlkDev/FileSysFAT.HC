#include "/Kernel/BlkDev/FATDateToDosCore.HC"

#include "/Kernel/BlkDev/FATDateFromDosCore.HC"

U0 FAT32Init(CDrv *dv)
{
  CFAT32Boot br32;
  Bool unlock;
  try {
    unlock=DrvLock(dv);
    dv->fs_type=FSt_FAT32;
    BlkRead(dv,&br32,dv->drv_offset,1);
    dv->file_system_info_sect=dv->drv_offset+br32.file_system_info_sect;
    dv->fat1=dv->drv_offset+br32.reserved_sects;
    dv->fat2=dv->fat1+br32.sects_per_fat;
    dv->data_area=dv->fat2+br32.sects_per_fat
	  -2*br32.sects_per_clus; //Starts at Clus 2
    dv->spc=br32.sects_per_clus;
    dv->root_clus=br32.root_clus;
    DrvFATBlkAlloc(dv);
    Free(dv->fis);
    dv->fis=AMAlloc(BLK_SIZE);
    BlkRead(dv,dv->fis,dv->file_system_info_sect,1);
    if (unlock)
      DrvUnlock(dv);
  } catch
    if (unlock)
      DrvUnlock(dv);
}

U0 FAT32Fmt(U8 drv_let,Bool quick=TRUE)
{
  CFAT32Boot *br=CAlloc(BLK_SIZE);
  CFAT32FileInfoSect *fis=CAlloc(BLK_SIZE);
  CDrv *dv=Let2Drv(drv_let);
  I64 i,l;
  try {
    DrvLock(dv);
    DrvTypeSet(drv_let,FSt_FAT32);
    dv->fs_type=FSt_FAT32;
    br->jump_and_nop[0]=OC_JMP_REL8;
    br->jump_and_nop[1]=offset(CFAT32Boot.code)-2;
    br->jump_and_nop[2]=OC_NOP;
    br->oem_name[0](I64)='MSWIN4.1';
    br->bytes_per_sect=BLK_SIZE;
    if	  (dv->size<= 500000)
      br->sects_per_clus=1;
    else if (dv->size<=2000000)
      br->sects_per_clus=2;
    else if (dv->size<=6000000)
      br->sects_per_clus=4;
    else if (dv->size<=12000000)
      br->sects_per_clus=8;
    else if (dv->size<=33000000)
      br->sects_per_clus=16;
    else if (dv->size<=67000000)
      br->sects_per_clus=32;
    else
      br->sects_per_clus=64;

    br->reserved_sects=32;
    br->copies_of_fat=2;
    br->media_desc=0xF8;
    br->sects=dv->size;
    l=(br->sects/br->sects_per_clus)>>(BLK_SIZE_BITS-2)+1;
    br->sects_per_fat=l;
    br->root_clus=2;
    br->file_system_info_sect=1;
    br->log_drv_num=0x80;
    br->ext_signature=0x29;
    br->serial_num=RandU32;
    MemCpy(br->vol_name,"NO NAME    ",11);
    br->fat_name[0](I64)='FAT32   ';
    br->signature=0xAA55;
    fis->signature1='RRaA';
    fis->signature2='rrAa';
    fis->free_clus=-1;
    fis->most_recently_alloced=0;
    fis->signature3=0xAA550000;

    if (quick)
      i=br->reserved_sects+2*l+4*br->sects_per_clus;
    else
      i=dv->size;
    BlkWriteZero(dv,dv->drv_offset,i);

    BlkWrite(dv,fis,dv->drv_offset+br->file_system_info_sect,1);
    BlkWrite(dv,br,dv->drv_offset,1);
    FAT32Init(dv);
    ClusAlloc(dv,0,1,FALSE); //Alloc #1
    br->root_clus=ClusAlloc(dv,0,1,FALSE);
    BlkWrite(dv,br,dv->drv_offset,1);
    FAT32Init(dv);
    DrvUnlock(dv);
  } catch
    DrvUnlock(dv);
  Free(br);
  Free(fis);
}

#include "/Kernel/BlkDev/FATNameCore.HC"

#include "/Kernel/BlkDev/FATLongNameCore.HC"

#include "/Kernel/BlkDev/FATDirReadCore.HC"

#include "/Kernel/BlkDev/FATDirFillCore.HC"

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

U8 *FAT32FileRead(CDrv *dv,U8 *cur_dir,U8 *filename,I64 *_size,I64 *_attr)
{
  U8 *buf=NULL;
  CDirEntry de;
  I64 c,blk_cnt,cur_dir_clus;
  DrvChk(dv);
  *_size=0;
  *_attr=0;
  if (dv->fs_type!=FSt_FAT32)
    PrintErr("Not FAT32 Drv\n");
  else
    try {
      DrvLock(dv);
      cur_dir_clus=Name2DirClus(dv,cur_dir);
      if (FAT32FileFind(dv,cur_dir_clus,filename,&de,FUF_JUST_FILES)) {
	blk_cnt=(de.size+BLK_SIZE-1)>>BLK_SIZE_BITS;
	buf=MAlloc(blk_cnt<<BLK_SIZE_BITS+1);
	c=de.clus;
	if (!(0<c<0x0FFFFFF8))
	  c=0x0FFFFFFF;
	else
	  c=ClusBlkRead(dv,buf,c,blk_cnt);
	buf[de.size]=0; //Terminate
	*_size=de.size;
	*_attr=FileAttr(de.name,de.attr);
      }
      DrvUnlock(dv);
    } catch
      DrvUnlock(dv);
  return buf;
}

Bool FAT32Cd(U8 *name,I64 cur_dir_clus)
{
  CDirEntry de;
  if (Fs->cur_dv->fs_type!=FSt_FAT32)
    PrintErr("Not FAT32 Drv\n");
  else if (FAT32FileFind(Fs->cur_dv,cur_dir_clus,name,&de,FUF_JUST_DIRS))
    return TRUE;
  else
    PrintErr("File not found: \"%s\".\n",name);
  return FALSE;
}

U0 FAT32FreeClus(CDrv *dv,I64 c)
{
  I64 next,saved_c=c;
  Bool unlock,unlock_break;
  DrvChk(dv);
  if (!(0<c<0x0FFFFFF8)) return;
  if (dv->fs_type!=FSt_FAT32)
    PrintErr("Not FAT32 Drv\n");
  else
    try {
      unlock_break=BreakLock;
      unlock=DrvLock(dv);
      DrvFATBlkClean(dv);
      do {
	DrvFATBlkSet(dv,c,0);
	next=dv->cur_fat_blk[c&(BLK_SIZE/4-1)];
	dv->cur_fat_blk[c&(BLK_SIZE/4-1)]=0;
	LBts(&dv->fat_blk_dirty,0);
	c=next;
      } while (0<c<0x0FFFFFF8);
      DrvFATBlkClean(dv,0);

      c=saved_c;
      do {
	DrvFATBlkSet(dv,c,1);
	next=dv->cur_fat_blk[c&(BLK_SIZE/4-1)];
	dv->cur_fat_blk[c&(BLK_SIZE/4-1)]=0;
	LBts(&dv->fat_blk_dirty,0);
	c=next;
      } while (0<c<0x0FFFFFF8);
      DrvFATBlkClean(dv,1);
      if (unlock)
	DrvUnlock(dv);
      if (unlock_break)
	BreakUnlock;
    } catch {
      if (unlock)
	DrvUnlock(dv);
      if (unlock_break)
	BreakUnlock;
    }
}

I64 FAT32AllocClus(CDrv *dv,I64 c,I64 cnt)
{
  Bool wrap_around=FALSE,unlock,unlock_break;
  I64 first=INVALID_CLUS,j,l;

  if (cnt<=0) return 0x0FFFFFFF;
  try {
    unlock_break=BreakLock;
    unlock=DrvLock(dv);
    l=(dv->size+dv->drv_offset-dv->data_area)/dv->spc-1;
    j=dv->fis->most_recently_alloced;
    while (cnt-->0) {
      while (TRUE) {
	j++;
	if (j<1) j=1;
	if (j>=l) {
	  if (wrap_around)
	    throw('Drv');
	  j=1;
	  wrap_around=TRUE;
	}
	DrvFATBlkSet(dv,j);
	if (!dv->cur_fat_blk[j&(BLK_SIZE/4-1)])
	  break;
      }
      if (!(0<first<0x0FFFFFF8))
	first=j;
      if (0<c<l) {
	DrvFATBlkSet(dv,c);
	dv->cur_fat_blk[c&(BLK_SIZE/4-1)]=j;
	LBts(&dv->fat_blk_dirty,0);
      }
      c=j;
    }

    if (0<c<l) {
      DrvFATBlkSet(dv,c);
      dv->cur_fat_blk[c&(BLK_SIZE/4-1)]=0x0FFFFFFF;
      LBts(&dv->fat_blk_dirty,0);
    }
    DrvFATBlkClean(dv);

    dv->fis->most_recently_alloced=j;
    dv->fis->free_clus=-1;
    BlkWrite(dv,dv->fis,dv->file_system_info_sect,1);
  } catch {
    if (unlock)
      DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  }
  if (unlock)
    DrvUnlock(dv);
  if (unlock_break)
    BreakUnlock;
  return first;
}

I64 FAT32AllocContiguousClus(CDrv *dv,I64 cnt)
{
  I64 i,first=1;
  Bool cont,unlock,unlock_break;

  if (cnt<=0) return 0x0FFFFFFF;
  try {
    unlock_break=BreakLock;
    unlock=DrvLock(dv);
    while (TRUE) {
      first++;
      i=0;
      cont=TRUE;
      while (cont && i<cnt) {
	if ((first+i+1)*dv->spc+dv->data_area>dv->size+dv->drv_offset)
	  throw('Drv');
	DrvFATBlkSet(dv,first+i);
	if (dv->cur_fat_blk[(first+i)&(BLK_SIZE/4-1)])
	  cont=FALSE;
	else
	  i++;
      }
      if (!cont)
	first=first+i;
      else {
	DrvFATBlkClean(dv);

	for (i=0;i<cnt;i++) {
	  DrvFATBlkSet(dv,first+i,0);
	  if (i+1==cnt)
	    dv->cur_fat_blk[(first+i)&(BLK_SIZE/4-1)]=0x0FFFFFFF;
	  else
	    dv->cur_fat_blk[(first+i)&(BLK_SIZE/4-1)]=first+i+1;
	  LBts(&dv->fat_blk_dirty,0);
	}
	DrvFATBlkClean(dv,0);

	for (i=0;i<cnt;i++) {
	  DrvFATBlkSet(dv,first+i,1);
	  if (i+1==cnt)
	    dv->cur_fat_blk[(first+i)&(BLK_SIZE/4-1)]=0x0FFFFFFF;
	  else
	    dv->cur_fat_blk[(first+i)&(BLK_SIZE/4-1)]=first+i+1;
	  LBts(&dv->fat_blk_dirty,0);
	}
	DrvFATBlkClean(dv,1);
	break;
      }
    }
  } catch {
    if (unlock)
      DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  }
  if (unlock)
    DrvUnlock(dv);
  if (unlock_break)
    BreakUnlock;
  return first;
}

Bool FAT32AliasScan(CDrv *dv,I64 first,CFAT32DirEntry *buf,U8 *alias,
	U8 *name,U8 *same_alias,Bool *same_found)
{// Read the directory without allocating clusters or changing it.
  I64 clus=first,next,i,count=dv->spc<<FAT32_ENTRIES_BITS,xsum=0,attr;
  CDirEntry long_name;
  Bool used=FALSE;
  U8 ch;
  *same_found=FALSE;
  MemSet(&long_name,0,sizeof(long_name));
  while (0<clus<0x0FFFFFF8) {
    ClusRead(dv,buf,clus,1);
    for (i=0;i<count;i++) {
      ch=*buf[i].name;
      if (!ch) return used;
      attr=buf[i].attr;
      if (ch!=0xE5 && attr&RS_ATTR_LONG_NAME_MASK==RS_ATTR_LONG_NAME)
        DirLongNameFill(&long_name,&buf[i],&xsum);
      else {
        if (ch!=0xE5 && !(attr&RS_ATTR_VOL_ID)) {
          if (xsum!=FATNameXSum(buf[i].name))
            MemSet(&long_name,0,sizeof(long_name));
          if (!*long_name.name) FATFromName(long_name.name,buf[i].name);
          if (!StrCmp(long_name.name,name)) {
            MemCpy(same_alias,buf[i].name,11);
            *same_found=TRUE;
          } else if (!MemCmp(buf[i].name,alias,11))
            used=TRUE;
        }
        MemSet(&long_name,0,sizeof(long_name));
        xsum=0;
      }
    }
    next=ClusNumNext(dv,clus);
    if (!(0<next<0x0FFFFFF8)) break;
    clus=next;
  }
  return used;
}

Bool FAT32AliasChoose(CDrv *dv,I64 first,CFAT32DirEntry *buf,
	CFAT32DirEntry *de,I64 *de_cnt,U8 *name)
{// Preserve an existing alias; otherwise find an unused short alias.
  U8 original[11],candidate[11],same[11],*suffix,*ptr;
  CFAT32DirEntryLong *ld=de;
  I64 n,l,p,i,xsum;
  Bool used,same_found;
  MemCpy(original,de[*de_cnt-1].name,11);
  MemCpy(candidate,original,11);
  used=FAT32AliasScan(dv,first,buf,candidate,name,same,&same_found);
  if (same_found) MemCpy(candidate,same,11);
  else if (used) {
    for (n=1;n<=999999;n++) {
      suffix=MStrPrint("~%d",n);
      l=StrLen(suffix);
      MemCpy(candidate,original,11);
      MemSet(candidate,CH_SPACE,8);
      p=0;
      while (p<8-l && original[p]!=CH_SPACE) {
        candidate[p]=original[p];
        p++;
      }
      MemCpy(candidate+p,suffix,l);
      Free(suffix);
      if (!FAT32AliasScan(dv,first,buf,candidate,name,same,&same_found)) break;
    }
    if (n>999999) return FALSE;
  }
  if (!MemCmp(candidate,original,11)) return TRUE;
  if (*de_cnt==1) {
    MemCpy(&de[1],&de[0],sizeof(CFAT32DirEntry));
    MemSet(&de[0],0,sizeof(CFAT32DirEntry));
    ptr=&de[0];
    ptr[0]=0x41;
    ptr[11]=RS_ATTR_LONG_NAME;
    l=StrLen(name);
    for (i=0;i<13;i++)
      if (i<l) ptr[fat_long_name_map[i]]=name[i];
      else if (i>l) ptr[fat_long_name_map[i]](U16)=0xFFFF;
    *de_cnt=2;
  }
  MemCpy(de[*de_cnt-1].name,candidate,11);
  xsum=FATNameXSum(candidate);
  for (i=0;i<*de_cnt-1;i++)
    ld[i].xsum=xsum;
  return TRUE;
}

Bool FAT32DirNew(CDrv *dv,U8 *cur_dir,CDirEntry *tmpde,Bool free_old_chain)
{
//See $LK,"::/Doc/CutCorners.DD"$.
  CFAT32DirEntry *buf,*last_buf,*tmp_buf,de[4];
  I64 i,attr,avail_cnt,de_cnt,c,
	cur_dir_entry,entries_per_clus,
	cur_dir_clus,xsum=0,last_dir_clus=INVALID_CLUS;
  U8 ch;
  Bool written=FALSE,unlock,unlock_break;
  CDirEntry long_name,existing,effective;
  if (!FAT32DirFill(&de,tmpde,&de_cnt,dv->fat32_local_time_offset))
    return FALSE;
  MemSet(&long_name,0,sizeof(CDirEntry));
  try {
    unlock_break=BreakLock;
    unlock=DrvLock(dv);
    cur_dir_clus=Name2DirClus(dv,cur_dir);
    if (FAT32FileFind(dv,cur_dir_clus,tmpde->name,&existing) &&
	  StrCmp(existing.name,tmpde->name)) {
      MemCpy(&effective,tmpde,sizeof(CDirEntry));
      StrCpy(effective.name,existing.name);
      tmpde=&effective;
      FAT32DirFill(&de,tmpde,&de_cnt,dv->fat32_local_time_offset);
    }
    buf     =MAlloc(BLK_SIZE*dv->spc);
    last_buf=CAlloc(BLK_SIZE*dv->spc);
    if (!FAT32AliasChoose(dv,cur_dir_clus,buf,&de,&de_cnt,tmpde->name)) {
      Free(last_buf);
      Free(buf);
      if (unlock) DrvUnlock(dv);
      if (unlock_break) BreakUnlock;
      return FALSE;
    }
    entries_per_clus=dv->spc<<FAT32_ENTRIES_BITS;
    ClusRead(dv,buf,cur_dir_clus,1);
    cur_dir_entry=0;
    while (ch=*buf[cur_dir_entry].name) {
      attr=buf[cur_dir_entry].attr;
      if (ch!=0xE5 && attr&RS_ATTR_LONG_NAME_MASK==RS_ATTR_LONG_NAME)
	DirLongNameFill(&long_name,&buf[cur_dir_entry],&xsum);
      else {
	avail_cnt=FAT32_ENTRIES_PER_BLK-cur_dir_entry
	      &(FAT32_ENTRIES_PER_BLK-1);
	for (i=0;i<avail_cnt;i++)
	  if (*buf[cur_dir_entry+i].name!=0xE5) {
	    if (*buf[cur_dir_entry+i].name)
	      avail_cnt=i;
	    break;
	  }
	if (ch==0xE5 && !written && avail_cnt>=de_cnt) {
	  MemCpy(&buf[cur_dir_entry],&de,de_cnt*sizeof(CFAT32DirEntry));
	  BlkWrite(dv,&buf[cur_dir_entry & -FAT32_ENTRIES_PER_BLK],
		dv->data_area+cur_dir_clus*dv->spc
		+cur_dir_entry>>FAT32_ENTRIES_BITS,1);
	  cur_dir_entry+=de_cnt-1; //gets inc'ed
	  written=TRUE;
	} else if (ch!=0xE5 && !(attr&RS_ATTR_VOL_ID)) {
	  if (xsum!=FATNameXSum(buf[cur_dir_entry].name))
	    MemSet(&long_name,0,sizeof(CDirEntry));
	  if (!*long_name.name)
	    FATFromName(long_name.name,buf[cur_dir_entry].name);
//Del old entry with same name
	  if (!StrCmp(long_name.name,tmpde->name)) {
	    if (free_old_chain)
	      FAT32FreeClus(dv,buf[cur_dir_entry].clus_lo+
		    buf[cur_dir_entry].clus_hi<<16);
	    if (!written) {
	      MemCpy(&buf[cur_dir_entry],&de[de_cnt-1],sizeof(CFAT32DirEntry));
	      BlkWrite(dv,&buf[cur_dir_entry & -FAT32_ENTRIES_PER_BLK],
		    dv->data_area+cur_dir_clus*dv->spc
		    +cur_dir_entry>>FAT32_ENTRIES_BITS,1);
	      written=TRUE;
	    } else {
	      *buf[cur_dir_entry].name=0xE5;
	      i=1;
	      while (i<=cur_dir_entry &&
		    buf[cur_dir_entry-i].attr&RS_ATTR_LONG_NAME_MASK
		    ==RS_ATTR_LONG_NAME)
		*buf[cur_dir_entry-i++].name=0xE5;
	      i--;
	      BlkWrite(dv,&buf[(cur_dir_entry-i)&-FAT32_ENTRIES_PER_BLK],
		    dv->data_area+cur_dir_clus*dv->spc
		    +(cur_dir_entry-i)>>FAT32_ENTRIES_BITS,
		    (i+FAT32_ENTRIES_PER_BLK)>>FAT32_ENTRIES_BITS);
	      if (i==cur_dir_entry && 0<last_dir_clus<0x0FFFFFF8) {
		i=1;
		while (i<=entries_per_clus &&
		      last_buf[entries_per_clus-i].attr
		      &RS_ATTR_LONG_NAME_MASK==RS_ATTR_LONG_NAME)
		  *last_buf[entries_per_clus-i++].name=0xE5;
		if (--i>0)
		  BlkWrite(dv,&buf[(entries_per_clus-i)&-FAT32_ENTRIES_PER_BLK],
			dv->data_area+last_dir_clus*dv->spc
			+(entries_per_clus-i)>>FAT32_ENTRIES_BITS,
			(i+FAT32_ENTRIES_PER_BLK-1)>>FAT32_ENTRIES_BITS);
	      }
	    }
	    break;
	  }
	}
	MemSet(&long_name,0,sizeof(CDirEntry));
      }
      if (++cur_dir_entry==entries_per_clus) {
	last_dir_clus=cur_dir_clus;
	tmp_buf=buf; buf=last_buf; last_buf=tmp_buf;
	c=ClusNumNext(dv,cur_dir_clus);
	if (!(0<c<0x0FFFFFF8)) {
	  c=ClusAlloc(dv,cur_dir_clus,1,FALSE);
	  MemSet(buf,0,BLK_SIZE*dv->spc);
	  ClusWrite(dv,buf,c,1);
	} else
	  ClusRead(dv,buf,c,1);
	cur_dir_clus=c;
	cur_dir_entry=0;
      }
    }
    if (!written) {
      avail_cnt=FAT32_ENTRIES_PER_BLK-cur_dir_entry & (FAT32_ENTRIES_PER_BLK-1);
      if (avail_cnt<de_cnt) {
	for (i=0;i<avail_cnt;i++)
	  *buf[cur_dir_entry+i].name=0xE5;
	BlkWrite(dv,&buf[cur_dir_entry &-FAT32_ENTRIES_PER_BLK],
	      dv->data_area+cur_dir_clus*dv->spc
	      +cur_dir_entry>>FAT32_ENTRIES_BITS,1);
	cur_dir_entry+=avail_cnt;
	if (cur_dir_entry==entries_per_clus) {
	  last_dir_clus=cur_dir_clus;
	  tmp_buf=buf; buf=last_buf; last_buf=tmp_buf;
	  cur_dir_clus=ClusAlloc(dv,cur_dir_clus,1);
	  cur_dir_entry=0;
	  MemSet(buf,0,BLK_SIZE*dv->spc);
	  ClusWrite(dv,buf,cur_dir_clus,1);
	}
      }
      MemCpy(&buf[cur_dir_entry],&de,de_cnt*sizeof(CFAT32DirEntry));
      BlkWrite(dv,&buf[cur_dir_entry &-FAT32_ENTRIES_PER_BLK],
	    dv->data_area+cur_dir_clus*dv->spc+
	    cur_dir_entry>>FAT32_ENTRIES_BITS,1);
      cur_dir_entry+=de_cnt;
      if (cur_dir_entry==entries_per_clus) {
	cur_dir_clus=ClusAlloc(dv,cur_dir_clus,1);
	MemSet(buf,0,BLK_SIZE*dv->spc);
	ClusWrite(dv,buf,cur_dir_clus,1);
      } else {
	MemSet(&buf[cur_dir_entry],0,sizeof(CFAT32DirEntry));
	BlkWrite(dv,&buf[cur_dir_entry &-FAT32_ENTRIES_PER_BLK],
	      dv->data_area+cur_dir_clus*dv->spc
	      +cur_dir_entry>>FAT32_ENTRIES_BITS,1);
      }
    }
    Free(last_buf);
    Free(buf);
    if (unlock)
      DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  } catch {
    if (unlock)
      DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  }
  return FALSE;
}

I64 FAT32FilesDel(CDrv *dv,U8 *cur_dir,U8 *files_find_mask,I64 fuf_flags,
		     Bool del_dir,Bool print_msg)
{
  CFAT32DirEntry *buf,*last_buf,*tmp_buf;
  I64 i,res=0,attr,xsum=0,last_dir_clus=INVALID_CLUS,
	cur_dir_entry,entries_per_clus,cur_dir_clus;
  U8 ch,short_name[16];
  Bool unlock_break;
  CDirEntry long_name;
  MemSet(&long_name,0,sizeof(CDirEntry));
  try {
    unlock_break=BreakLock;
    DrvLock(dv);
    cur_dir_clus=Name2DirClus(dv,cur_dir);
    buf     =MAlloc(BLK_SIZE*dv->spc);
    last_buf=CAlloc(BLK_SIZE*dv->spc);
    entries_per_clus=dv->spc<<FAT32_ENTRIES_BITS;
    ClusRead(dv,buf,cur_dir_clus,1);
    cur_dir_entry=0;
    while (ch=*buf[cur_dir_entry].name) {
      attr=buf[cur_dir_entry].attr;
      if (ch!=0xE5 && ch!='.') {
	if (attr&RS_ATTR_LONG_NAME_MASK==RS_ATTR_LONG_NAME)
	  DirLongNameFill(&long_name,&buf[cur_dir_entry],&xsum);
	else {
	  if (!(attr & RS_ATTR_VOL_ID) &&
		(del_dir || !(attr & RS_ATTR_DIR))) {
	    if (xsum!=FATNameXSum(buf[cur_dir_entry].name))
	      MemSet(&long_name,0,sizeof(CDirEntry));
	    if (!*long_name.name)
	      FATFromName(long_name.name,buf[cur_dir_entry].name);
	    FATFromName(short_name,buf[cur_dir_entry].name);
	    if (FilesFindMatch(long_name.name,files_find_mask,fuf_flags) ||
		!StrICmp(short_name,files_find_mask) &&
		FilesFindMatch(long_name.name,"*",fuf_flags)) {
	      if (!(attr & RS_ATTR_DIR)) res++;
	      if (print_msg)
		"Del %s\n",long_name.name;
	      *buf[cur_dir_entry].name=0xE5;
	      i=1;
	      while (i<=cur_dir_entry &&
		    buf[cur_dir_entry-i].attr&RS_ATTR_LONG_NAME_MASK
		    ==RS_ATTR_LONG_NAME)
		*buf[cur_dir_entry-i++].name=0xE5;
	      i--;
	      BlkWrite(dv,&buf[(cur_dir_entry-i)&-FAT32_ENTRIES_PER_BLK],
		    dv->data_area+cur_dir_clus*dv->spc
		    +(cur_dir_entry-i)>>FAT32_ENTRIES_BITS,
		    (i+FAT32_ENTRIES_PER_BLK)>>FAT32_ENTRIES_BITS);
	      if (i==cur_dir_entry && last_dir_clus!=INVALID_CLUS) {
		i=1;
		while (i<=entries_per_clus &&
		      last_buf[entries_per_clus-i].attr
		      &RS_ATTR_LONG_NAME_MASK==RS_ATTR_LONG_NAME)
		  *last_buf[entries_per_clus-i++].name=0xE5;
		if (--i>0)
		  BlkWrite(dv,&buf[(entries_per_clus-i)&-FAT32_ENTRIES_PER_BLK],
			dv->data_area+last_dir_clus*dv->spc
			+(entries_per_clus-i)>>FAT32_ENTRIES_BITS,
			(i+FAT32_ENTRIES_PER_BLK-1)>>FAT32_ENTRIES_BITS);
	      }
	      FAT32FreeClus(dv,buf[cur_dir_entry].clus_lo+
		    buf[cur_dir_entry].clus_hi<<16);
	    }
	  }
	  MemSet(&long_name,0,sizeof(CDirEntry));
	}
      } else
	MemSet(&long_name,0,sizeof(CDirEntry));
      if (++cur_dir_entry==entries_per_clus) {
	last_dir_clus=cur_dir_clus;
	cur_dir_clus=ClusNumNext(dv,cur_dir_clus,1);
	tmp_buf=buf; buf=last_buf; last_buf=tmp_buf;
	ClusRead(dv,buf,cur_dir_clus,1);
	cur_dir_entry=0;
      }
    }
    Free(buf);
    Free(last_buf);
    DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  } catch {
    DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  }
  return res;
}

I64 FAT32FileWrite(CDrv *dv,U8 *cur_dir,U8 *name,U8 *buf,I64 size,
	CDate cdt,I64 attr)
{
  CDirEntry de,existing;
  I64 c=0,blk_cnt;
  Bool contiguous;
  MemSet(&de,0,sizeof(CDirEntry));
  if (size<0) size=0;
  if (dv->fs_type!=FSt_FAT32)
    PrintErr("Not FAT32 Drv\n");
  else if (!CFileNameTo(de.name,name))
    PrintErr("Invalid FileName: \"%s\".\n",name);
  else {
    if (FAT32FileFind(dv,Name2DirClus(dv,cur_dir),de.name,&existing,
	  FUF_JUST_FILES))
      StrCpy(de.name,existing.name);
    FAT32FilesDel(dv,cur_dir,de.name,0,FALSE,FALSE);
    if (attr & RS_ATTR_CONTIGUOUS)
      contiguous=TRUE;
    else
      contiguous=FALSE;
    de.size=size;
    if (blk_cnt=(size+BLK_SIZE-1)>>BLK_SIZE_BITS)
      c=ClusAlloc(dv,0,(blk_cnt+dv->spc-1)/dv->spc,contiguous);
    else
      c=0x0FFFFFFF;
    de.clus=c;
    de.attr=attr;
    de.datetime=cdt;
    if (blk_cnt)
      ClusBlkWrite(dv,buf,c,blk_cnt);
    FAT32DirNew(dv,cur_dir,&de,TRUE);
  }
  return c;
}

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

Bool FAT32MkDir(CDrv *dv,U8 *cur_dir,U8 *name,I64 entry_cnt)
{
  I64 c,cur_dir_clus=Name2DirClus(dv,cur_dir),
//Rough estimate of size
	size=CeilU64((entry_cnt+2)<<FAT32_ENTRIES_BITS,dv->spc<<BLK_SIZE_BITS);
  U8 *buf=CAlloc(size);
  CDirEntry d_native;
  CFAT32DirEntry *dFAT=buf;
  Bool unlock_break;

  try {
    unlock_break=BreakLock;
    c=FileWrite(name,buf,size,0,RS_ATTR_DIR);
    MemSet(&d_native,0,sizeof(CDirEntry));
    d_native.attr=RS_ATTR_DIR;
    *d_native.name='.';
    d_native.name[1]=0;
    d_native.clus=c;
    d_native.size=0;
    d_native.datetime=Now;
    FAT32DirFill(dFAT,&d_native,NULL,dv->fat32_local_time_offset);
    dFAT++;

    MemSet(&d_native,0,sizeof(CDirEntry));
    d_native.attr=RS_ATTR_DIR;
    *d_native.name='.';
    d_native.name[1]='.';
    d_native.name[2]=0;
    d_native.clus=cur_dir_clus;
    d_native.size=0;
    d_native.datetime=Now;
    FAT32DirFill(dFAT,&d_native,NULL,dv->fat32_local_time_offset);
    ClusWrite(dv,buf,c,1);
    Free(buf);
    if (unlock_break)
      BreakUnlock;
  } catch
    if (unlock_break)
      BreakUnlock;
  return TRUE;
}
