extern Bool I386RawBlocks(CDrv *drive,U8 *buffer,I64 block,I64 count,Bool write);
U0 RetainedATATransferContract()
{
  CDrv *dv=Let2Drv('C');CBlkDev *bd=dv->bd;
  CDirEntry de;
  U8 seed[1536],expected[1536],actual[1538],*file;
  I64 i,size,r,w,max_reads=bd->max_reads,max_writes=bd->max_writes;
  Bool unlock;
  if(dv->fs_type!=FSt_REDSEA||bd->type!=BDT_ATA||bd->blk_size!=512)throw('AX0001',TRUE);
  for(i=0;i<1536;i++){seed[i]=i*17+i/512;expected[i]=i*29+7+i/512;}
  if(!FileWrite("C:/ata-transfer-probe.DATA",seed,1536))throw('AX0002',TRUE);
  if(!FileFind("C:/ata-transfer-probe.DATA",&de,FUF_JUST_FILES))throw('AX0003',TRUE);
  if(de.size!=1536||de.clus<dv->drv_offset||de.clus+3>dv->drv_offset+dv->size)throw('AX0004',TRUE);
  unlock=DrvLock(dv);
  MemSet(actual,0x5A,1538);r=blkdev.read_cnt;
  ATAReadBlks(bd,actual+1,de.clus,2);
  if(blkdev.read_cnt!=r+2)throw('AX0005',TRUE);
  for(i=0;i<1024;i++)if(actual[i+1]!=seed[i])throw('AX0006',TRUE);
  if(actual[0]!=0x5A||actual[1025]!=0x5A)throw('AX0007',TRUE);
  bd->max_reads=2;bd->max_writes=2;
  r=blkdev.read_cnt;w=blkdev.write_cnt;
  if(!ATARBlks(dv,NULL,de.clus,0)||!ATAWBlks(dv,NULL,de.clus,0))throw('AX0008',TRUE);
  if(blkdev.read_cnt!=r||blkdev.write_cnt!=w)throw('AX0009',TRUE);
  if(!ATAWBlks(dv,expected,de.clus,3)||blkdev.write_cnt!=w+3)throw('AX0010',TRUE);
  MemSet(actual,0x5A,1538);
  if(!ATARBlks(dv,actual+1,de.clus,3)||blkdev.read_cnt!=r+3)throw('AX0011',TRUE);
  for(i=0;i<1536;i++)if(actual[i+1]!=expected[i])throw('AX0012',TRUE);
  if(actual[0]!=0x5A||actual[1537]!=0x5A)throw('AX0013',TRUE);
  if(DrvLock(dv))throw('AX0014',TRUE);
  bd->max_reads=max_reads;bd->max_writes=max_writes;
  if(unlock)DrvUnlock(dv);
  if(!I386RawBlocks(dv,actual+1,de.clus,3,FALSE))throw('AX0015',TRUE);
  for(i=0;i<1536;i++)if(actual[i+1]!=expected[i])throw('AX0016',TRUE);
  file=FileRead("C:/ata-transfer-probe.DATA",&size);
  if(!file||size!=1536)throw('AX0017',TRUE);
  for(i=0;i<size;i++)if(file[i]!=expected[i])throw('AX0018',TRUE);
  Free(file);Free(de.full_name);
  if(!FileDel("C:/ata-transfer-probe.DATA"))throw('AX0019',TRUE);
}
RetainedATATransferContract;
