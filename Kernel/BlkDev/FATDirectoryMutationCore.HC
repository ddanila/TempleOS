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
	cur_dir_clus,old_clus,xsum=0,last_dir_clus=INVALID_CLUS;
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
	    old_clus=buf[cur_dir_entry].clus_lo+
		  buf[cur_dir_entry].clus_hi<<16;
	    if (free_old_chain && old_clus!=tmpde->clus)
	      FAT32FreeClusUntil(dv,old_clus,
		    FAT32ChainOverlap(dv,old_clus,tmpde->clus));
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
		  BlkWrite(dv,&last_buf[(entries_per_clus-i)&-FAT32_ENTRIES_PER_BLK],
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
  Bool unlock=FALSE,unlock_break=FALSE;
  CDirEntry long_name;
  MemSet(&long_name,0,sizeof(CDirEntry));
  try {
    unlock_break=BreakLock;
    unlock=DrvLock(dv);
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
		  BlkWrite(dv,&last_buf[(entries_per_clus-i)&-FAT32_ENTRIES_PER_BLK],
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
    if (unlock) {DrvUnlock(dv);unlock=FALSE;}
    if (unlock_break) {unlock_break=FALSE;BreakUnlock;}
  } catch {
    if (unlock)
      DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  }
  return res;
}

