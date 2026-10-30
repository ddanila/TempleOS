I64 CBContract()
{
  CDrv d;I64 mask=0;Bool caught;
  MemCpy(&d,Fs->cur_dv,sizeof(CDrv));
  d.fs_type=FSt_REDSEA;if(Clus2Blk(&d,0x12345678)==0x12345678)mask|=1;
  d.fs_type=FSt_FAT32;d.data_area=4096;d.spc=8;
  if(Clus2Blk(&d,123)==5080)mask|=2;
  d.fs_type=255;caught=FALSE;
  try Clus2Blk(&d,1);
  catch {caught=Fs->except_ch=='Drv';Fs->catch_except=TRUE;}
  if(caught)mask|=4;
  d.dv_signature=0;caught=FALSE;
  try Clus2Blk(&d,1);
  catch {caught=Fs->except_ch=='Drv';Fs->catch_except=TRUE;}
  if(caught)mask|=8;
  return mask;
}
