U0 MountFileContract(I64 drive)
{
  CDrv dv;
  CBlkDev bd;
  CDrv *saved;
  CDrv *mounted;
  U8 *home;
  U8 *image;
  U8 *path;
  U8 *data;
  CBlkDev *device;
  CDirEntry de;
  I64 size;
  Bool caught=FALSE;
  saved=blkdev.let_to_drv[25];
  home=DirCur;
  image=MStrPrint("%C:/MountProbe.ISO.C",drive);
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.drv_let='Z';dv.bd=&bd;
  dv.drv_offset=88;dv.size=128;dv.fs_type=FSt_REDSEA;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.type=BDT_RAM;bd.first_drv_let='Z';
  bd.max_blk=215;bd.drv_offset=88;bd.blk_size=512;bd.init_root_dir_blks=2;
  bd.flags=BDF_INITIALIZED;bd.RAM_dsk=CAlloc(216*512);
  blkdev.let_to_drv[25]=&dv;CallExtStr("RedSeaFmt",'Z',TRUE);
  if(!CallExtStr("RedSeaValidate",'Z')||dv.drv_offset!=88||dv.size!=128)throw('MountFmt',TRUE);
  if(!DirMk("Z:/Sub")||!FileWrite("Z:/Sub/test.DATA","mounted-data",12))throw('MountSrc',TRUE);
  if(!FileWrite(image,bd.RAM_dsk,216*512))throw('MountImg',TRUE);
  path=MStrPrint("%C:/Sub/test.DATA",MountFile(image));mounted=Let2Drv(*path);
  device=mounted->bd;
  if(mounted->drv_offset!=88||mounted->size!=128||device->type!=BDT_ISO_FILE_READ||
      device->lock_fwding!=Let2BlkDev(drive)||!device->file_dsk)throw('MountRec',TRUE);
  if(!FileFind(path,&de,FUF_JUST_FILES)||de.size!=12)throw('MntFind',TRUE);
  Free(de.full_name);data=FileRead(path,&size);
  if(!data||size!=12||MemCmp(data,"mounted-data",12))throw('MntRead',TRUE);Free(data);
  path[3]=0;CatPrint(path,"Sub");
  if(!Cd(path))throw('MountCd',TRUE);
  data=FileRead("test.DATA",&size);
  if(!data||size!=12||MemCmp(data,"mounted-data",12))throw('MountRel',TRUE);Free(data);
  try BlkWrite(mounted,bd.RAM_dsk,mounted->root_clus,1);
  catch {caught=TRUE;Fs->catch_except=TRUE;}
  if(!caught||!Cd(home))throw('MountRO',TRUE);
  Unmount(*path);
  if(Let2Drv(*path,FALSE)||device->bd_signature||device->file_dsk||device->file_dsk_name)throw('MountDel',TRUE);
  if(Del(image,,,FALSE)!=1)throw('MountEnd',TRUE);
  CallExtStr("RedSeaFreeFreeLst",&dv);Free(dv.cur_fat_blk);Free(bd.RAM_dsk);
  blkdev.let_to_drv[25]=saved;Free(path);Free(image);Free(home);
}
