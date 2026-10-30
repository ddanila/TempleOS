#include "/Kernel/BlkDev/BlockDevLockCore.HC"

#include "/Kernel/BlkDev/BlockDevInitCore.HC"

#include "/Kernel/BlkDev/BlockDevReleaseCore.HC"

#include "/Kernel/BlkDev/BlockDevSlotCore.HC"

U0 BlkDevDel(CBlkDev *bd)
{//Delete BlkDev
  DrvBlkDevDel(bd);
  FClose(bd->file_dsk);
  Free(bd->file_dsk_name);
  Free(bd->dev_id_record);
  MemSet(bd,0,sizeof(CBlkDev));
}

#include "/Kernel/BlkDev/BlockDevLookupCore.HC"
