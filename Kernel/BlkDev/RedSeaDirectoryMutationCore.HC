U0 RedSeaDirReparentChildren(CDrv *dv,U8 *directory,I64 clus)
{//A relocated directory is the parent of every live child directory.
  CDirEntry *entry=directory-offset(CDirEntry.start),*parent;
  I64 i,entries=entry->size/CDIR_SIZE;
  U8 *sector=NULL;
  entry(U8 *)+=2*CDIR_SIZE;
  try {
    sector=MAlloc(BLK_SIZE);
    for(i=2;i<entries && *entry->name;i++,entry(U8 *)+=CDIR_SIZE)
      if(entry->attr&RS_ATTR_DIR && !(entry->attr&RS_ATTR_DELETED)) {
        BlkRead(dv,sector,entry->clus,1);
        parent=sector+CDIR_SIZE-offset(CDirEntry.start);
        //A new child can still be awaiting its initial dot records.
        if(parent->name[0]=='.' && parent->name[1]=='.' && !parent->name[2]) {
          parent->clus=clus;
          BlkWrite(dv,sector,entry->clus,1);
        }
      }
  } catch {Free(sector);throw;}
  Free(sector);
}

Bool RedSeaDirNew(CDrv *dv,U8 *cur_dir,CDirEntry *tmpde,Bool free_old_chain)
{
  CDirEntry *buf,*buf2,*ptr,de2;
  CRedSeaBoot *br;
  I64 c,ch,i=1,j=0,n=BLK_SIZE/CDIR_SIZE,dir_size,cur_dir_clus;
  Bool written=FALSE,unlock,unlock_break;
  U8 *tmp,*parent_dir;
  try {
    unlock_break=BreakLock;
    tmpde->attr|=RS_ATTR_CONTIGUOUS;
    unlock=DrvLock(dv);
    cur_dir_clus=Name2DirClus(dv,cur_dir);
    buf2=MAlloc(BLK_SIZE);
    BlkRead(dv,buf2,cur_dir_clus,1);

    ptr=buf2(U8 *)-offset(CDirEntry.start);
    buf=MAlloc(ptr->size);
    BlkRead(dv,buf,cur_dir_clus,ptr->size>>BLK_SIZE_BITS);

    dir_size=ptr->size;
    ptr=buf(U8 *)-offset(CDirEntry.start)+CDIR_SIZE;
    Free(buf2);
    while (TRUE) {
      if (!(ch=*ptr->name)) {
	if (!written)
	  MemCpy(&ptr->start,&tmpde->start,CDIR_SIZE);
	if ((i+1)*CDIR_SIZE+j<<BLK_SIZE_BITS<dir_size)
	  BlkWrite(dv,buf(U8 *)+j<<BLK_SIZE_BITS,cur_dir_clus+j,1);
	else {
	  buf2=CAlloc(dir_size+BLK_SIZE);
	  MemCpy(buf2,buf,dir_size);
	  RedSeaFreeClus(dv,cur_dir_clus,dir_size>>BLK_SIZE_BITS);
	  dir_size+=BLK_SIZE;
	  c=ClusAlloc(dv,0,dir_size>>BLK_SIZE_BITS,TRUE);
	  Free(buf);
	  buf=buf2;
	  ptr=buf(U8 *)-offset(CDirEntry.start);
	  ptr->size=dir_size;
	  ptr->clus=c;
          if(cur_dir_clus==dv->root_clus) {
            ptr(U8 *)+=CDIR_SIZE;
            ptr->clus=c;
            ptr(U8 *)-=CDIR_SIZE;
          }
	  BlkWrite(dv,buf,c,dir_size>>BLK_SIZE_BITS);
          RedSeaDirReparentChildren(dv,buf,c);
	  if (cur_dir_clus==dv->root_clus) {
	    br=CAlloc(BLK_SIZE);
	    BlkRead(dv,br,dv->drv_offset,1);
	    br->root_clus=c;
	    BlkWrite(dv,br,dv->drv_offset,1);
	    Free(br);
	    dv->root_clus=c;
	  } else {
	    tmp=StrNew(cur_dir);
	    parent_dir=StrNew(cur_dir);
	    StrLastRem(parent_dir,"/",tmp);
	    if (!*parent_dir) {
	      Free(parent_dir);
	      parent_dir=StrNew("/");
	    }
	    if (RedSeaFileFind(dv,Name2DirClus(dv,parent_dir),
		  tmp,&de2,FUF_JUST_DIRS)) {
	      de2.clus=c;
	      de2.size=dir_size;
	      RedSeaDirNew(dv,parent_dir,&de2,FALSE);
	    } else
	      throw('Drv');
	    Free(tmp);
	    Free(parent_dir);
	  }
	}
	break;
      } else if (ptr->attr & RS_ATTR_DELETED) {
	if (!written) {
	  MemCpy(&ptr->start,&tmpde->start,CDIR_SIZE);
	  BlkWrite(dv,buf(U8 *)+j<<BLK_SIZE_BITS,cur_dir_clus+j,1);
	  written=TRUE;
	}
      } else {
	if (!StrCmp(tmpde->name,ptr->name)) {
	  if (free_old_chain)
	    RedSeaFreeClus(dv,ptr->clus,
		  (ptr->size+BLK_SIZE-1)>>BLK_SIZE_BITS);
	  if (!written)
	    MemCpy(&ptr->start,&tmpde->start,CDIR_SIZE);
	  else
	    ptr->attr|=RS_ATTR_DELETED;
	  BlkWrite(dv,buf(U8 *)+j<<BLK_SIZE_BITS,cur_dir_clus+j,1);
	  break;
	}
      }
      ptr(U8 *)+=CDIR_SIZE;
      if (++i>=n) {
	j++;
	i=0;
      }
    }
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

I64 RedSeaFilesDel(CDrv *dv,U8 *cur_dir,U8 *files_find_mask,I64 fuf_flags,
		     Bool del_dir,Bool print_msg)
{
  CDirEntry *buf,*buf2,*ptr;
  I64 i=0,res=0,ch,j=0,n=BLK_SIZE/CDIR_SIZE,cur_dir_clus;
  Bool unlock_break;
  try {
    unlock_break=BreakLock;
    DrvLock(dv);
    cur_dir_clus=Name2DirClus(dv,cur_dir);
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
      else if (!(ptr->attr & RS_ATTR_DELETED) && ch!='.' && (del_dir ||
	    !(ptr->attr & RS_ATTR_DIR)) &&
	    FilesFindMatch(ptr->name,files_find_mask,fuf_flags)) {
	if (!(ptr->attr & RS_ATTR_DIR)) res++;
	if (print_msg)
	  "Del %s\n",ptr->name;
	ptr->attr|=RS_ATTR_DELETED;
	BlkWrite(dv,buf(U8 *)+j<<BLK_SIZE_BITS,cur_dir_clus+j,1);
	RedSeaFreeClus(dv,ptr->clus,
	      (ptr->size+BLK_SIZE-1)>>BLK_SIZE_BITS);
      }
      ptr(U8 *)+=CDIR_SIZE;
      if (++i>=n) {
	j++;
	i=0;
      }
    }
    Free(buf);
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

