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
