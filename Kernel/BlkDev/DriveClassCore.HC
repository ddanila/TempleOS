I64 Let2BlkDevType(U8 drv_let)
{//Drv letter to BlkDev Type. drv_let=0 not allowed. See $LK,"BDT_NULL",A="MN:BDT_NULL"$.
  drv_let=Let2Let(drv_let);
  if ('A'<=drv_let<='B')
    return BDT_RAM;
  if ('C'<=drv_let<='L')
    return BDT_ATA;
  if ('M'<=drv_let<='P')
    return BDT_ISO_FILE_READ;
  if ('Q'<=drv_let<='S')
    return BDT_ISO_FILE_WRITE;
  if ('T'<=drv_let<='Z')
    return BDT_ATAPI;
  return BDT_NULL;
}

