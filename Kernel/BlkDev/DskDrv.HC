#include "/Kernel/BlkDev/DriveLockCore.HC"

#include "/Kernel/BlkDev/DriveReleaseCore.HC"

#include "/Kernel/BlkDev/DriveSlotCore.HC"

#include "/Kernel/BlkDev/DriveDeleteCore.HC"

#include "/Kernel/BlkDev/DriveDeviceDeleteCore.HC"

#include "/Kernel/BlkDev/DriveFATAllocCore.HC"

#include "/Kernel/BlkDev/DriveFATCacheCore.HC"

#include "/Kernel/BlkDev/DriveLetterCore.HC"

#include "/Kernel/BlkDev/DriveClassCore.HC"

#include "/Kernel/BlkDev/DriveLookupCore.HC"

#include "/Kernel/BlkDev/DriveWritableCore.HC"

#include "/Kernel/BlkDev/DriveMediaLifecycleCore.HC"

#include "/Kernel/BlkDev/DriveMapCore.HC"


U8 *DrvSerialNum(U8 drv_let=0)
{//20 bytes max.
  CBlkDev *bd=Let2BlkDev(drv_let);
  U16 *st,*res=NULL;
  I64 i;
  if (bd->dev_id_record) {
    st=CAlloc(20+1);
    for (i=0;i<10;i++)
      st[i]=EndianU16(bd->dev_id_record[10+i]);
    res=MStrUtil(st,SUF_REM_LEADING|SUF_REM_TRAILING);
    Free(st);
  }
  return res;
}

U8 *DrvModelNum(U8 drv_let=0)
{//40 bytes max.
  CBlkDev *bd=Let2BlkDev(drv_let);
  U16 *st,*res=NULL;
  I64 i;
  if (bd->dev_id_record) {
    st=CAlloc(40+1);
    for (i=0;i<20;i++)
      st[i]=EndianU16(bd->dev_id_record[27+i]);
    res=MStrUtil(st,SUF_REM_LEADING|SUF_REM_TRAILING);
    Free(st);
  }
  return res;
}

#include "/Kernel/BlkDev/DriveTextAttrCore.HC"

U0 DrvRep()
{//Drive report.
  CDrv *dv;
  CBlkDev *bd;
  I64 ch,i,drv_let,attr;
  U8 *st;
  "\nDefined Drives:\n";
  for (i=0,dv=blkdev.drvs;i<DRVS_NUM;i++,dv++) {
    if (dv->dv_signature==DRV_SIGNATURE_VAL) {
      bd=dv->bd;
      drv_let=Drv2Let(dv);
      if (Bt(&dv->fs_type,FStf_DISABLE))
	ch='-';
      else if (drv_let==blkdev.boot_drv_let)
	ch=':';
      else
	ch='+';
      attr=DrvTextAttrGet(drv_let);
      "$$FG,%d$$$$BG,%d$$%C %-8Z %-10Z %04X %04X %02X\n",
	    attr&15,attr>>4,drv_let,dv->fs_type&FSG_TYPE_MASK,"ST_DRV_TYPES",
	    bd->type,"ST_BLKDEV_TYPES",bd->base0,bd->base1,bd->unit;
      if (st=DrvModelNum(drv_let)) {
	"   Model# :%s\n",st;
	Free(st);
      }
      if (st=DrvSerialNum(drv_let)) {
	"   Serial#:%s\n",st;
	Free(st);
      }
      if (bd->type==BDT_ISO_FILE_READ || bd->type==BDT_ISO_FILE_WRITE)
	"   File=\"%s\"\n",bd->file_dsk_name;
      "   %016X-%016X\n$$FG$$$$BG$$",dv->drv_offset,dv->drv_offset+dv->size-1;
    }
  }
  "Home Dir:\"%s\"\n",blkdev.home_dir;
}
