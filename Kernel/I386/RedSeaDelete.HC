#include "/Kernel/I386/RedSea.HH"
extern Bool I386RedSeaValid(CI386RedSea *v);
extern Bool I386RedSeaDirectory(CI386RedSea *v,I64 block,U8 *sector,I64 *size);
public I64 I386RedSeaDelete(CI386RedSea *volume,I64 directory,U8 *name)
{//1 removed, 0 absent, -1 invalid/I/O. Caller must retire all references first.
  U8 sector[512],*raw;
  CI386RedSeaEntry entry;
  I64 status,dir_size,index,i,blocks;
  if (!I386RedSeaValid(volume) || !volume->disk->flush ||
      !I386RedSeaDirectory(volume,directory,sector,&dir_size) || (sector[0]&1)) return -1;
  status=I386RedSeaFind(volume,directory,name,&entry);
  if (status<=0) return status;
  if (entry.attr&0x11) return -1;
  //Find has validated the live record; exclusive ownership keeps it stable.
  for (index=0;index<dir_size/64;index++) {
    if (!(index&7) && index && !I386RedSeaSectorRead(volume,directory+index/8,sector)) goto io_fail;
    raw=sector+(index&7)*64;
    if (!raw[2]) goto io_fail;
    if (!(raw[1]&1)) {
      i=0;
      while (i<38 && raw[2+i]==entry.name[i]) {
        if (!entry.name[i]) {
          raw[1]|=1;
          if (!I386RedSeaSectorWrite(volume,directory+index/8,sector) ||
              !I386RedSeaFlush(volume)) goto io_fail;
          //Only a flushed tombstone permits releasing the referenced allocation.
          blocks=(entry.size+511)/512;
          if (blocks && (!I386RedSeaFree(volume,entry.block,blocks) ||
                         !I386RedSeaFlush(volume))) goto io_fail;
          return 1;
        }
        i++;
      }
    }
  }
io_fail:
  volume->signature=0;
  return -1;
}
