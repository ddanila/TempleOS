#include "/Kernel/BlkDev/FATDateToDosCore.HC"

#include "/Kernel/BlkDev/FATDateFromDosCore.HC"

#include "/Kernel/BlkDev/FATInitCore.HC"

U0 FAT32Fmt(U8 drv_let,Bool quick=TRUE)
{
  CFAT32Boot *br=CAlloc(BLK_SIZE);
  CFAT32FileInfoSect *fis=CAlloc(BLK_SIZE);
  CDrv *dv=Let2Drv(drv_let);
  I64 i,l;
  try {
    DrvLock(dv);
    DrvTypeSet(drv_let,FSt_FAT32);
    dv->fs_type=FSt_FAT32;
    br->jump_and_nop[0]=OC_JMP_REL8;
    br->jump_and_nop[1]=offset(CFAT32Boot.code)-2;
    br->jump_and_nop[2]=OC_NOP;
    br->oem_name[0](I64)='MSWIN4.1';
    br->bytes_per_sect=BLK_SIZE;
    if	  (dv->size<= 500000)
      br->sects_per_clus=1;
    else if (dv->size<=2000000)
      br->sects_per_clus=2;
    else if (dv->size<=6000000)
      br->sects_per_clus=4;
    else if (dv->size<=12000000)
      br->sects_per_clus=8;
    else if (dv->size<=33000000)
      br->sects_per_clus=16;
    else if (dv->size<=67000000)
      br->sects_per_clus=32;
    else
      br->sects_per_clus=64;

    br->reserved_sects=32;
    br->copies_of_fat=2;
    br->media_desc=0xF8;
    br->sects=dv->size;
    l=(br->sects/br->sects_per_clus)>>(BLK_SIZE_BITS-2)+1;
    br->sects_per_fat=l;
    br->root_clus=2;
    br->file_system_info_sect=1;
    br->log_drv_num=0x80;
    br->ext_signature=0x29;
    br->serial_num=RandU32;
    MemCpy(br->vol_name,"NO NAME    ",11);
    br->fat_name[0](I64)='FAT32   ';
    br->signature=0xAA55;
    fis->signature1='RRaA';
    fis->signature2='rrAa';
    fis->free_clus=-1;
    fis->most_recently_alloced=0;
    fis->signature3=0xAA550000;

    if (quick)
      i=br->reserved_sects+2*l+4*br->sects_per_clus;
    else
      i=dv->size;
    BlkWriteZero(dv,dv->drv_offset,i);

    BlkWrite(dv,fis,dv->drv_offset+br->file_system_info_sect,1);
    BlkWrite(dv,br,dv->drv_offset,1);
    FAT32Init(dv);
    ClusAlloc(dv,0,1,FALSE); //Alloc #1
    br->root_clus=ClusAlloc(dv,0,1,FALSE);
    BlkWrite(dv,br,dv->drv_offset,1);
    FAT32Init(dv);
    DrvUnlock(dv);
  } catch
    DrvUnlock(dv);
  Free(br);
  Free(fis);
}

#include "/Kernel/BlkDev/FATNameCore.HC"

#include "/Kernel/BlkDev/FATLongNameCore.HC"

#include "/Kernel/BlkDev/FATDirReadCore.HC"

#include "/Kernel/BlkDev/FATDirFillCore.HC"

#include "/Kernel/BlkDev/FATFileFindCore.HC"

#include "/Kernel/BlkDev/FATReadDirectoryCore.HC"

#include "/Kernel/BlkDev/FATAllocationCore.HC"

#include "/Kernel/BlkDev/FATDirectoryMutationCore.HC"

#include "/Kernel/BlkDev/FATWriteCore.HC"

#include "/Kernel/BlkDev/FATFilesFindCore.HC"

#include "/Kernel/BlkDev/FATMakeDirectoryCore.HC"
