#ifndef DRIVE_SLOT_RECORD
#define DRIVE_SLOT_RECORD &blkdev.drvs[i]
#endif
#ifndef DRIVE_SLOT_SIGNATURE
#define DRIVE_SLOT_SIGNATURE blkdev.drvs[i].dv_signature
#endif
CDrv *DrvMakeFreeSlot(U8 drv_let)
{//Make a slot free for a new drv, like during $LK,"Mount",A="MN:Mount"$().
//!!! drv_let is not a $LK,"remapped",A="MN:DrvMap"$ drv.
  I64 i=Let2Let(drv_let)-'A';
  CDrv *res;
  if (!(0<=i<DRVS_NUM))
    throw('Drv');
  res=DRIVE_SLOT_RECORD;
  MemSet(res,0,sizeof(CDrv));
  res->drv_let='A'+i;
  return res;
}

U8 DrvNextFreeLet(U8 first_drv_let='C')
{//Locate free slot for new drv, like during $LK,"Mount",A="MN:Mount"$().
//!!! first_drv_let is not a $LK,"remapped",A="MN:DrvMap"$ drv.
  I64 i=Let2Let(first_drv_let)-'A',type=Let2BlkDevType(first_drv_let);
  if (!(0<=i<DRVS_NUM))
    throw('Drv');
  do
    if (DRIVE_SLOT_SIGNATURE!=DRV_SIGNATURE_VAL) {
      if (Let2BlkDevType(i+'A')!=type)
	throw('Drv');
      else
	return i+'A';
    }
  while (++i<DRVS_NUM);
  throw('Drv');
  return 0; //Never gets here.
}

