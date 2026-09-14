#include "/Kernel/I386/RedSea.HH"
extern Bool I386RedSeaValid(CI386RedSea *v);
extern Bool I386RedSeaDirectory(CI386RedSea *v,I64 block,U8 *sector,I64 *size);
extern U0 I386RedSeaPutWord(U8 *p,U64 value);
public I64 I386RedSeaReplace(CI386RedSea *volume,I64 directory,U8 *name,U8 *buffer,I64 size,I64 datetime=0)
{//1 replaced, 0 absent/full, -1 invalid/I/O. Requires exclusive file ownership.
  U8 sector[512],*raw;
  CI386RedSeaEntry old,fresh;
  I64 status,dir_size,index,i,blocks;
  if (!I386RedSeaValid(volume) || !volume->disk->flush || size<0 || size>0xFFFFFFFF ||
      (size && !buffer) || (buffer+0)(U64)>0x100000000-size ||
      !I386RedSeaDirectory(volume,directory,sector,&dir_size) || (sector[0]&1)) return -1;
  status=I386RedSeaFind(volume,directory,name,&old);
  if (status<=0) return status;
  if (old.attr&0x11) return -1;
  for (index=0;index<dir_size/64;index++) {
    if (!(index&7) && index && !I386RedSeaSectorRead(volume,directory+index/8,sector)) return -1;
    raw=sector+(index&7)*64;
    if (!raw[2]) return -1;
    if (!(raw[1]&1)) {
      i=0;
      while (i<38 && raw[2+i]==old.name[i]) {
        if (!old.name[i]) goto found;
        i++;
      }
    }
  }
  return -1;
found:
  blocks=(size+511)/512;
  if (blocks>volume->start+volume->sectors-volume->first) return 0;
  fresh.attr=old.attr; fresh.block=0; fresh.size=size;
  if (blocks) {
    fresh.block=I386RedSeaAlloc(volume,blocks);
    if (!fresh.block) return 0;
    if (fresh.block<0) return -1;
    if (I386RedSeaWrite(volume,&fresh,0,buffer,size)!=size) goto io_fail;
  }
  if (!I386RedSeaFlush(volume)) goto io_fail;
  //Publish the new extent in the same slot, retaining the name and attributes.
  I386RedSeaPutWord(raw+40,fresh.block);
  I386RedSeaPutWord(raw+48,size);
  I386RedSeaPutWord(raw+56,datetime);
  if (!I386RedSeaSectorWrite(volume,directory+index/8,sector) ||
      !I386RedSeaFlush(volume)) goto io_fail;
  blocks=(old.size+511)/512;
  if (blocks && (!I386RedSeaFree(volume,old.block,blocks) || !I386RedSeaFlush(volume)))
    goto io_fail;
  return 1;
io_fail:
  volume->signature=0;
  return -1;
}
