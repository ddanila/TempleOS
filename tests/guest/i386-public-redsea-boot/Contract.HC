U0 PublicRedSeaBootContract()
{
  CDrv *dv=Let2Drv('C');
  CRedSeaBoot br;
  if(sizeof(CRedSeaBoot)!=512)throw('RSBoot',TRUE);
  if(offset(CRedSeaBoot.drv_offset)!=8||offset(CRedSeaBoot.sects)!=16)throw('RSBoot',TRUE);
  if(offset(CRedSeaBoot.root_clus)!=24||offset(CRedSeaBoot.bitmap_sects)!=32)throw('RSBoot',TRUE);
  if(offset(CRedSeaBoot.unique_id)!=40||offset(CRedSeaBoot.signature2)!=510)throw('RSBoot',TRUE);
  ATAReadBlks(dv->bd,&br,dv->drv_offset,1);
  if(br.signature!=MBR_PT_REDSEA||br.signature2!=0xAA55)throw('RSBoot',TRUE);
  if(br.drv_offset!=dv->drv_offset||br.sects!=dv->size)throw('RSBoot',TRUE);
  if(br.root_clus!=dv->root_clus)throw('RSBoot',TRUE);
  if(dv->data_area!=dv->drv_offset+br.bitmap_sects)throw('RSBoot',TRUE);
  if(dv->fat1!=dv->drv_offset+1||dv->fat2!=dv->fat1)throw('RSBoot',TRUE);
}
PublicRedSeaBootContract;
