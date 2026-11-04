U0 DriveTypeSetContract()
{
  CDrv *dv=Let2Drv('C');CBlkDev *bd=dv->bd;
  CMasterBoot mbr,observed;U8 backup[512];
  Bool unlock,caught=FALSE;
  if(sizeof(CMBRPrt)!=16||sizeof(CMasterBoot)!=512||offset(CMasterBoot.p)!=446)throw('MBR1',TRUE);
  if(bd->type!=BDT_ATA||bd->first_drv_let!='C')throw('MBR2',TRUE);
  unlock=DrvLock(dv);
  ATAReadBlks(bd,backup,0,1);
  MemSet(&mbr,0,512);MemSet(mbr.code,0x6D,440);mbr.signature=0xAA55;
  mbr.p[0].type=MBR_PT_FAT32a;mbr.p[0].offset=1;mbr.p[0].size=bd->max_blk;
  ATAWriteBlks(bd,&mbr,0,1);
  if(!DrvTypeSet('C',FSt_REDSEA))throw('MBR3',TRUE);
  ATAReadBlks(bd,&observed,0,1);
  mbr.p[0].type=MBR_PT_REDSEA;mbr.p[0].active=0x80;
  if(MemCmp(&mbr,&observed,512))throw('MBR4',TRUE);
  if(!DrvTypeSet('C',FSt_FAT32))throw('MBR5',TRUE);
  ATAReadBlks(bd,&observed,0,1);mbr.p[0].type=MBR_PT_FAT32a;
  if(MemCmp(&mbr,&observed,512))throw('MBR6',TRUE);
  try DrvTypeSet('C',FSt_ISO9660);
  catch {caught=TRUE;Fs->catch_except=TRUE;}
  if(!caught)throw('MBR7',TRUE);
  ATAReadBlks(bd,&observed,0,1);
  if(MemCmp(&mbr,&observed,512)||DrvLock(dv))throw('MBR8',TRUE);
  ATAWriteBlks(bd,backup,0,1);ATAReadBlks(bd,&observed,0,1);
  if(MemCmp(backup,&observed,512))throw('MBR9',TRUE);
  if(unlock)DrvUnlock(dv);
}
DriveTypeSetContract;
