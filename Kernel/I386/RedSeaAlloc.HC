#include "/Kernel/I386/RedSea.HH"
extern Bool I386RedSeaValid(CI386RedSea *v);
extern Bool I386RedSeaDirectory(CI386RedSea *v,I64 block,U8 *sector,I64 *size);
Bool I386RedSeaBitmapValid(CI386RedSea *v)
{
  return I386RedSeaValid(v) && v->first>=v->start+2 &&
    (v->first-v->start-1)*4096>=v->start+v->sectors-v->first+1;
}
Bool I386RedSeaBitmapChange(CI386RedSea *v,I64 block,I64 count,Bool set,Bool strict=TRUE)
{//Preflight all bits before writes. I/O failure invalidates this mounted view.
  U8 sector[512],mask;
  I64 pass,index,end=block+count-(v->first-1),limit,i,lba;
  for (pass=0;pass<2;pass++) {
    index=block-(v->first-1);
    while (index<end) {
      lba=v->start+1+index/4096;
      if (!I386RedSeaSectorRead(v,lba,sector)) goto io_fail;
      limit=(index/4096+1)*4096;
      if (limit>end) limit=end;
      while (index<limit) {
        i=(index&4095)/8; mask=1<<(index&7);
        if (!pass) {
          if (strict && ((sector[i]&mask)!=0)==set) return FALSE;
        } else {
          if (set) sector[i]|=mask;
          else sector[i]&=~mask;
        }
        index++;
      }
      if (pass && !I386RedSeaSectorWrite(v,lba,sector)) goto io_fail;
    }
  }
  return TRUE;
io_fail:
  v->signature=0;
  return FALSE;
}
I64 I386RedSeaAllocCore(CI386RedSea *volume,I64 count,I64 *owned_block)
{//First contiguous free run; 0 exhausted, -1 invalid/I/O, otherwise disk sector.
  U8 sector[512];
  I64 block,index,cached=-1,run=0;
  if (!I386RedSeaBitmapValid(volume) || count<1 ||
      count>volume->start+volume->sectors-volume->first) return -1;
  for (block=volume->first;block<volume->start+volume->sectors;block++) {
    index=block-(volume->first-1);
    if (cached!=index/4096) {
      cached=index/4096;
      if (!I386RedSeaSectorRead(volume,volume->start+1+cached,sector)) {
        volume->signature=0; return -1;
      }
    }
    if (sector[(index&4095)/8]&(1<<(index&7))) run=0;
    else run++;
    if (run==count) {
      block=block+1-count;
      if(owned_block)*owned_block=block;
      if (!I386RedSeaBitmapChange(volume,block,count,TRUE)) return -1;
      return block;
    }
  }
  return 0;
}
public I64 I386RedSeaAlloc(CI386RedSea *volume,I64 count)
{return I386RedSeaAllocCore(volume,count,0);}
public I64 I386RedSeaAllocOwned(CI386RedSea *volume,I64 count,I64 *owned_block)
{
  if(!owned_block || *owned_block)return -1;
  return I386RedSeaAllocCore(volume,count,owned_block);
}
Bool I386RedSeaFreeCore(CI386RedSea *volume,I64 block,I64 count,Bool strict)
{//Caller must own an unreferenced extent. No directory removal or cache flush.
  U8 sector[512];
  I64 root_size;
  if (!I386RedSeaBitmapValid(volume) || count<1 || block<volume->first ||
      block>=volume->start+volume->sectors || count>volume->start+volume->sectors-block ||
      !I386RedSeaDirectory(volume,volume->root,sector,&root_size)) return FALSE;
  if (block<volume->root+root_size/512 && block+count>volume->root) return FALSE;
  return I386RedSeaBitmapChange(volume,block,count,FALSE,strict);
}
public Bool I386RedSeaFree(CI386RedSea *volume,I64 block,I64 count)
{return I386RedSeaFreeCore(volume,block,count,TRUE);}
public Bool I386RedSeaReleaseOwned(CI386RedSea *volume,I64 block,I64 count)
{//Already-clear bits are valid after an interrupted owned reservation/release.
  return I386RedSeaFreeCore(volume,block,count,FALSE);
}
