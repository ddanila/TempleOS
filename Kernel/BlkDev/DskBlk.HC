#define ZERO_BUF_SIZE	2048
U0 BlkWriteZero(CDrv *dv,I64 blk,I64 cnt)
{//Fill blk cnt with zeros in Drv.
  I64 n;
  U8 *z=CAlloc(ZERO_BUF_SIZE<<BLK_SIZE_BITS);
  Bool show_progress;
  if (cnt>ZERO_BUF_SIZE && dv->bd->type!=BDT_RAM) {
    progress1=0; progress1_max=cnt;
    StrCpy(progress1_desc,"Zeroing");
    show_progress=TRUE;
  } else
    show_progress=FALSE;
  while (cnt>0) {
    n=cnt;
    if (n>ZERO_BUF_SIZE)
      n=ZERO_BUF_SIZE;
    BlkWrite(dv,z,blk,n);
    blk+=n;
    cnt-=n;
    if (show_progress)
      progress1+=n;
    Yield;  //Prevent locking
  }
  Free(z);
  if (show_progress) {
    *progress1_desc=0;
    progress1=progress1_max=0;
  }
}

#include "/Kernel/BlkDev/BlockReadWriteCore.HC"
