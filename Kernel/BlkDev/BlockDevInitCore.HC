Bool BlkDevInit(CBlkDev *bd)
{
  CDirEntry de;
  U8 buf[STR_LEN];
  CDrv *dv=Let2Drv(bd->first_drv_let);
  Bool res=FALSE;
  if (!LBts(&bd->flags,BDf_INITIALIZED)) {
    bd->flags|=BDF_INIT_IN_PROGRESS;
    switch (bd->type) {
      case BDT_RAM:
	if (!bd->RAM_dsk) {
	  bd->RAM_dsk=AMAlloc((bd->max_blk+1)<<BLK_SIZE_BITS);
	  bd->max_blk=MSize(bd->RAM_dsk)>>BLK_SIZE_BITS-1;
	}
	dv->fs_type=FSt_REDSEA;
	dv->size=bd->max_blk+1-bd->drv_offset;
	if (RedSeaValidate(bd->first_drv_let))
	  RedSeaInit(dv);
	else
	  RedSeaFmt(bd->first_drv_let);
	res=TRUE;
	break;
      case BDT_ISO_FILE_READ:
	if (FileFind(bd->file_dsk_name,&de,FUF_JUST_FILES)) {
	  bd->max_blk=de.size>>BLK_SIZE_BITS-1;
	  try bd->file_dsk=FOpen(bd->file_dsk_name,"rc",bd->max_blk+1);
	  catch {
	    if (Fs->except_ch=='File')
	      PrintErr("Not Contiguous.  Move file to filename.ISO.C.\n");
	    Fs->catch_except=TRUE;
	  }
	  if (bd->file_dsk) {
	    dv->fs_type=FSt_REDSEA;
	    dv->size=bd->max_blk+1-bd->drv_offset;
	    if (RedSeaValidate(bd->first_drv_let)) {
	      RedSeaInit(dv);
	      res=TRUE;
	    } else
	      PrintErr("Not RedSea\n");
	  }
	}
	break;
      case BDT_ISO_FILE_WRITE:
	if (!bd->file_dsk_name) {
	  StrPrint(buf,"%C:/Drv%C.ISO.C",
		blkdev.boot_drv_let,bd->first_drv_let);
	  bd->file_dsk_name=AStrNew(buf);
	}
	if (bd->max_blk<7)
	  bd->max_blk=7;
	bd->file_dsk=FOpen(bd->file_dsk_name,"wc",bd->max_blk+1);
	dv->fs_type=FSt_REDSEA;
	dv->size=bd->max_blk+1-bd->drv_offset;
	RedSeaFmt(bd->first_drv_let);
	CallExtStr("RedSeaISO9660",bd->file_dsk_name,bd->first_drv_let);
	res=TRUE;
	break;
      case BDT_ATA:
	bd->max_reads=128;
	bd->max_writes=1;
	res=ATAInit(bd);
	break;
      case BDT_ATAPI:
//0xFFFF*4 is too big for my taste
	bd->max_reads=0x800*4;
//max of maybe a quarter of disk cache
	if (bd->max_reads>blkdev.cache_size/BLK_SIZE/4)
	  bd->max_reads=blkdev.cache_size/BLK_SIZE/4 & ~3;
	if (bd->max_reads<128)
	  bd->max_reads=128;
	bd->max_writes=0xFFFF*4;
	if (res=ATAInit(bd))
	  dv->size=bd->max_blk+1;
	break;
    }
    if (res && bd->flags & BDF_READ_CACHE)
      DskCacheInvalidate(dv);
    bd->flags&=~BDF_INIT_IN_PROGRESS;
  } else
    res=TRUE;
  return res;
}

