U0 Fmt(I64 drv_let,Bool quick=TRUE,Bool confirm=TRUE,I64 type=FSt_FAT32)
{//Format hard drive or RAM drive.
//$BK,1$Warning:$BK,0$ Destroys all prev info.
  //quick=FALSE means fill entire drive with zeros.
  //Choose $LK,"FSt_FAT32",A="MN:FSt_FAT32"$ or $LK,"FSt_REDSEA",A="MN:FSt_REDSEA"$.
  //You don't format a CD/DVD with this.
  CDrv *dv=Let2Drv(drv_let);
  Bool old_silent=IsSilent;
  if (confirm && !AreYouSure)
    return;
  if (!dv)  {
    PrintErr("Invalid Drive\n");
    return;
  }
  switch (type) {
    case FSt_FAT32:
      if (dv->bd->type==BDT_ATA) {
	Silent;
	Drv(drv_let);
	Silent(old_silent);
	FAT32Fmt(drv_let,quick);
	DskCacheInvalidate(Let2Drv(drv_let));
	Drv(drv_let);
	break;
      }
      "Using RedSea File System.\n";
    case FSt_REDSEA:
      Silent;
      Drv(drv_let);
      Silent(old_silent);
      RedSeaFmt(drv_let,quick);
      DskCacheInvalidate(Let2Drv(drv_let));
      Drv(drv_let);
      break;
    default:
      PrintErr("File System Not Supported\n");
  }
}
