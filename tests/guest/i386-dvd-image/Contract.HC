U0 DVDLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 DVDCheck(I64 drive)
{
  CDrv dv,fat,*saved=blkdev.let_to_drv[25],*saved_fat=blkdev.let_to_drv[24];
  CBlkDev bd,ram;
  I64 v[8],size,i;
  U8 *name=StrNew("Y:/DVDRead.ISO"),*data,*first,*s;
  Bool caught=FALSE,bytes_ok=TRUE;
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.drv_let='Z';dv.bd=&bd;
  dv.size=260;dv.fs_type=FSt_ISO9660;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.first_drv_let='Z';bd.type=BDT_ATAPI;
  bd.base0=0x170;bd.base1=0x376;bd.unit=1;bd.blk_size=2048;
  bd.flags=BDF_INITIALIZED|BDF_READ_ONLY;bd.max_reads=128;bd.max_writes=128;
  MemSet(&fat,0,sizeof(CDrv));MemSet(&ram,0,sizeof(CBlkDev));
  fat.dv_signature=DRV_SIGNATURE_VAL;fat.drv_let='Y';fat.bd=&ram;
  fat.size=8192;fat.fs_type=FSt_FAT32;
  ram.bd_signature=BD_SIGNATURE_VAL;ram.type=BDT_RAM;ram.first_drv_let='Y';
  ram.max_blk=8191;ram.blk_size=512;ram.flags=BDF_INITIALIZED;
  ram.RAM_dsk=CAlloc(8192*512);blkdev.let_to_drv[24]=&fat;
  CallExtStr("FAT32Fmt",'Y',TRUE);
  blkdev.let_to_drv[25]=&dv;
  DVDLog("DVD READ start\n");DVDImageRead('Z',name);
  data=FileRead(name,&size);v[0]=data && size==133120;
  if(data)for(i=0;i<size;i++)if(data[i]!=((i*13+5)&255))bytes_ok=FALSE;
  v[1]=bytes_ok;v[2]=!(bd.locked_flags&1);v[3]=bd.flags==(BDF_INITIALIZED|BDF_READ_ONLY);
  s=MStrPrint("EXPORT dvd-read.bin %X %X\n",data,size);DVDLog(s);Free(s);first=data;
  bd.type=BDT_RAM;
  try DVDImageWrite('Z',name);
  catch {caught=Fs->except_ch=='BlkDev';Fs->catch_except=TRUE;}
  v[4]=caught;v[5]=!(bd.flags&BDF_READ_ONLY_OVERRIDE);bd.type=BDT_ATAPI;
  data=FileRead(name,&size);v[6]=data && size==133120;
  s=MStrPrint("EXPORT dvd-after-reject.bin %X %X\n",data,size);DVDLog(s);Free(s);
  v[7]=!(bd.locked_flags&1);
  s=MStrPrint("EXPORT dvd-checks.bin %X %X\n",v,sizeof(v));DVDLog(s);Free(s);
  DVDLog("DVD IMAGE DONE\n");Sleep(1000);
  Free(first);Free(data);Free(name);blkdev.let_to_drv[25]=saved;
  Free(fat.cur_fat_blk);Free(fat.fis);Free(ram.RAM_dsk);blkdev.let_to_drv[24]=saved_fat;
}
