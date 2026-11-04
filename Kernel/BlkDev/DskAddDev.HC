#include "/Kernel/BlkDev/BlockDevAddCore.HC"

Bool DrvEnable(U8 drv_let,Bool val)
{//Can unmount or remount, but not mount the first time.
  CDrv *dv;
  if (dv=Let2Drv(drv_let,FALSE))
    return !LBEqu(&dv->fs_type,FStf_DISABLE,!val);
  else
    return FALSE;
}

I64 SysGetI64()
{
  U8 st[STR_LEN];
  GetS(st,STR_LEN,FALSE);
  return Str2I64(st,16);
}

Bool GetBaseUnit(CBlkDev *bd)
{
  I64 ch;
  Bool probe;
  #exe {
    if (kernel_cfg->opts[CFG_DONT_PROBE])
      StreamPrint("probe=FALSE;");
    else
      StreamPrint("probe=TRUE;");
  };
  if (!probe || !BootDVDProbeAll(bd)) {
    "\nDon't worry.  This is not a product\n"
	  "registration.	TempleOS just needs the\n"
	  "I/O port numbers for the CD/DVD.\n"
	  "\nRetry the ports above or check Windows\n"
	  "system information under I/O ports for\n"
	  "'IDE', 'ATA' or 'SATA'.\n"
	  "In Linux, use 'lspci -v' for ports.\n"
	  "\n\nEnter 4-digit hex I/O Port number.\n"
	  "CD/DVD I/O Port Base0: 0x";
    bd->base0=SysGetI64;
    bd->base1=0;
    bd->unit =0;
    if (bd->base0) {
      "\nUnit (0 or 1): ";
      do ch=GetChar(,FALSE);
      while (!('0'<=ch<='1'));
      '' ch;
      bd->unit=ch-'0';
      blkdev.dvd_boot_is_good=BootDVDProbe(bd);
      return TRUE;
    } else {
      blkdev.dvd_boot_is_good=FALSE;
      return FALSE;
    }
  }
  return FALSE;
}

U0 BlkDevsInitAll()
{
  CBlkDev *bd;
  I64 i;
  blkdev.blkdevs=CAlloc(sizeof(CBlkDev)*BLKDEVS_NUM);
  blkdev.drvs=CAlloc(sizeof(CDrv)*DRVS_NUM);
  for (i=0;i<DRVS_NUM;i++)
    blkdev.let_to_drv[i]=&blkdev.drvs[i];
  #exe {
    if (kernel_cfg->opts[CFG_MOUNT_IDE_AUTO])
      StreamPrint("MountIDEAuto;");
    StreamPrint("#exe {Option(OPTf_WARN_PAREN,OFF);}");
    StreamDoc(kernel_cfg->add_dev);
    StreamPrint("#exe {Option(OPTf_WARN_PAREN,ON);}");
  };
}
