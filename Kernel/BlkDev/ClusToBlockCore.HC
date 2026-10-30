I64 Clus2Blk(CDrv *dv,I64 c)
{//Drv clus num to blk num.
  DrvChk(dv);
  switch (dv->fs_type) {
    case FSt_REDSEA:
      return c;
    case FSt_FAT32:
      return dv->data_area+c*dv->spc;
    default:
      throw('Drv');
  }
}

