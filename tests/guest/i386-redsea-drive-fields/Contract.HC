I64 RedSeaDriveFields(CDrv *dv)
{
  U8 *header=CAlloc(512);I64 mask=0;
  if(!dv || !RBRead(dv,header,dv->drv_offset,1))goto field_done;
  if(header[3]==0x88 && header[510]==0x55 && header[511]==0xAA &&
      *(header+8)(I64 *)==dv->drv_offset && *(header+16)(I64 *)==dv->size)mask|=1;
  if(dv->fs_type==FSt_REDSEA && dv->spc==1)mask|=2;
  if(dv->data_area==dv->drv_offset+*(header+32)(I64 *))mask|=4;
  if(dv->fat1==dv->drv_offset+1 && dv->fat2==dv->fat1)mask|=8;
  if(dv->root_clus==*(header+24)(I64 *))mask|=16;
field_done:
  Free(header);return mask;
}
