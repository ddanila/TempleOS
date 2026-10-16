CBlkDev *BlkDevChk(CBlkDev *bd,Bool except=TRUE)
{//Check for valid BlkDev. Throw exception.
  if (!bd || bd->bd_signature!=BD_SIGNATURE_VAL ||
	!(BDT_NULL<bd->type<BDT_TYPES_NUM)) {
    if (except)
      throw('BlkDev');
    else
      return NULL;
  } else
    return bd;
}

CBlkDev *Let2BlkDev(U8 drv_let=0,Bool except=TRUE)
{//Drv letter to BlkDev ptr.
  CDrv *dv;
  if (dv=Let2Drv(drv_let,except))
    return BlkDevChk(dv->bd,except);
  else
    return NULL;
}
