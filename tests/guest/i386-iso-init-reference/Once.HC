extern Bool ISOInit(CDrv *dv,I64 blk);
U0 ISOReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 ISOInitContract()
{
  CDrv dv;CBlkDev bd;CISOPriDesc *primary,*supplement;
  CRedSeaBoot *br;Bool caught=FALSE;
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.bd=&bd;dv.size=256;dv.fs_type=FSt_REDSEA;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.type=BDT_RAM;bd.flags=BDF_INITIALIZED;
  bd.first_drv_let=Fs->cur_dv->drv_let;bd.blk_size=2048;bd.max_blk=255;
  bd.RAM_dsk=CAlloc(256*512);primary=bd.RAM_dsk;supplement=bd.RAM_dsk+2048;
  primary->type=ISOT_PRI_VOL_DESC;MemCpy(primary->id,"CD001",5);
  supplement->type=ISOT_SUPPLEMENTARY_DESC;MemCpy(supplement->id,"CD001",5);
  supplement->vol_space_size.little=64;supplement->root_dir_record.loc.little=9;
  StrCpy(supplement->publisher_id,"Reference");
  if(!DrvLock(&dv)||!ISOInit(&dv,0))throw('ISO1',TRUE);
  if(dv.fs_type!=FSt_ISO9660||dv.spc!=4||dv.size!=256||dv.root_clus!=9||dv.drv_offset||bd.drv_offset||DrvLock(&dv))throw('ISO2',TRUE);
  DrvUnlock(&dv);
  br=bd.RAM_dsk+76*512;br->signature=MBR_PT_REDSEA;br->signature2=0xAA55;
  br->drv_offset=76;br->sects=180;br->root_clus=80;br->bitmap_sects=1;
  StrCpy(supplement->publisher_id,"TempleOS RedSea");
  if(!ISOInit(&dv,0))throw('ISO3',TRUE);
  if(dv.fs_type!=FSt_REDSEA||dv.spc!=1||dv.size!=180||dv.root_clus!=80||dv.drv_offset!=76||bd.drv_offset!=76||dv.fat1!=77||!dv.cur_fat_blk)throw('ISO4',TRUE);
  primary->type=ISOT_TERMINATOR;
  if(!DrvLock(&dv))throw('ISO5',TRUE);
  try ISOInit(&dv,0);
  catch {caught=TRUE;Fs->catch_except=TRUE;}
  if(!caught||dv.fs_type!=FSt_ISO9660||dv.spc!=4||dv.drv_offset||bd.drv_offset||dv.root_clus||dv.data_area||DrvLock(&dv))throw('ISO6',TRUE);
  DrvUnlock(&dv);Free(dv.cur_fat_blk);Free(bd.RAM_dsk);
}
ISOInitContract;
U8 *iso_layout=MStrPrint("ISO LAYOUT %d %d %d %d %d %d\n",sizeof(CPalindromeU16),sizeof(CPalindromeU32),sizeof(CISODirEntry),sizeof(CISOPriDesc),offset(CISOPriDesc.root_dir_record),offset(CISOPriDesc.publisher_id));
ISOReport(iso_layout);Free(iso_layout);
ISOReport("PASS private RAM ISO initializer\n");
ISOReport("DONE ISO initializer\n");
