CDrv fp_drive;
CBlkDev fp_device;
U0 FPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}

U0 FPSetup(U8 *default_filename=NULL)
{
  MemSet(&fp_drive,0,sizeof(CDrv));MemSet(&fp_device,0,sizeof(CBlkDev));
  fp_drive.dv_signature=DRV_SIGNATURE_VAL;fp_drive.drv_let='Z';fp_drive.bd=&fp_device;
  fp_drive.drv_offset=88;fp_drive.size=128;fp_drive.fs_type=FSt_REDSEA;
  fp_device.bd_signature=BD_SIGNATURE_VAL;fp_device.type=BDT_RAM;
  fp_device.first_drv_let='Z';fp_device.max_blk=215;fp_device.drv_offset=88;
  fp_device.blk_size=512;fp_device.init_root_dir_blks=2;fp_device.flags=BDF_INITIALIZED;
  fp_device.RAM_dsk=CAlloc(216*512);
  blkdev.let_to_drv[25]=&fp_drive;
  CallExtStr("RedSeaFmt",'Z',TRUE);
  if(!DirMk("Z:/Proof")||!FileWrite("Z:/Root.TXT","root",4)||
      !FileWrite("Z:/Proof/Leaf.TXT","leaf",4)||!Cd("Z:/"))
    throw('TreeInit',TRUE);
  if(default_filename)blkdev.tmp_filename=StrNew(default_filename,adam_task);
  FPLog("TREE READY\n");
}

U0 FPExport(U8 *path)
{
  I64 size;
  U8 *data=FileRead(path,&size),*line;
  if(!data)throw('TreeOut',TRUE);
  line=MStrPrint("EXPORT tree.DD %X %X\n",data,size);
  FPLog(line);Sleep(2000);Free(line);Free(data);
}
