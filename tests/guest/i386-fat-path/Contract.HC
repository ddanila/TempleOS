U8 *FatPathContract()
{
  CDrv dv;
  CBlkDev bd;
  CDrv *saved=blkdev.let_to_drv[25];
  U8 *home=DirCur;
  U8 *data=MAlloc(1537);
  U8 *read;
  U8 *snapshot;
  CFile *stream;
  CDirEntry de;
  CDirEntry *entries;
  CDirEntry *entry;
  I64 i,size,count=0;
  CFAT32Boot boot;
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.drv_let='Z';dv.bd=&bd;
  dv.size=4096;dv.fs_type=FSt_FAT32;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.type=BDT_RAM;bd.first_drv_let='Z';
  bd.max_blk=4095;bd.blk_size=512;bd.flags=BDF_INITIALIZED;
  bd.RAM_dsk=CAlloc(4096*512);blkdev.let_to_drv[25]=&dv;
  CallExtStr("FAT32Fmt",'Z',TRUE);
  if(!BlkRead(&dv,&boot,0,1)||boot.signature!=0xAA55||boot.copies_of_fat!=2)throw('FatBoot',TRUE);
  dv.root_clus=0;dv.spc=0;CallExtStr("FAT32Init",&dv);
  if(dv.root_clus!=boot.root_clus||dv.spc!=boot.sects_per_clus||!dv.fis)throw('FatInit',TRUE);
  for(i=0;i<1537;i++)data[i]=i*17+i/512;
  if(!DirMk("Z:/Sub")||!DirMk("Z:/Sub/Grand"))throw('FatDirs',TRUE);
  if(!FileWrite("Z:/Sub/alpha.DATA",data,1537)||
      !FileWrite("Z:/Sub/beta.DATA.Z",data,1537)||
      !FileWrite("Z:/Sub/Long sample name.DATA",data,1537))throw('FatWrite',TRUE);
  if(!Copy("Z:/Sub/alpha.DATA","Z:/Sub/copy.DATA")||
      !Move("Z:/Sub/copy.DATA","Z:/Sub/moved.DATA")||FileFind("Z:/Sub/copy.DATA"))throw('FatCopy',TRUE);
  stream=FOpen("Z:/Sub/stream.DATA","w",3);
  if(!stream||!FBlkWrite(stream,data,0,3))throw('FatStm',TRUE);FClose(stream);
  read=FileRead("Z:/Sub/beta.DATA.Z",&size);
  if(!read||size!=1537||MemCmp(read,data,size))throw('FatZip',TRUE);Free(read);
  read=FileRead("Z:/Sub/Long sample name.DATA",&size);
  if(!read||size!=1537||MemCmp(read,data,size))throw('FatLong',TRUE);Free(read);
  if(!FileFind("Z:/Sub/moved.DATA",&de,FUF_JUST_FILES)||de.size!=1537)throw('FatFind',TRUE);
  Free(de.full_name);
  if(!Cd("Z:/Sub/Grand"))throw('FatCd',TRUE);
  read=FileRead("alpha.DATA",&size);
  if(!read||size!=1537||MemCmp(read,data,size))throw('FatPar',TRUE);Free(read);
  read=FileRead("../stream.DATA",&size);
  if(!read||size!=1536||MemCmp(read,data,size))throw('FatRel',TRUE);Free(read);
  entries=FilesFind("Z:/Sub/*",FUF_JUST_FILES);
  for(entry=entries;entry;entry=entry->next)count++;
  DirTreeDel(entries);
  if(count!=5||Dir("Z:/Sub/*",TRUE)!=8||!Cd(home))throw('FatList',TRUE);
  snapshot=MAlloc(4096*512);MemCpy(snapshot,bd.RAM_dsk,4096*512);
  Free(dv.cur_fat_blk);Free(dv.fis);Free(bd.RAM_dsk);
  blkdev.let_to_drv[25]=saved;Free(home);Free(data);
  return snapshot;
}
