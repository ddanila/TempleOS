#include "/Kernel/I386/RedSea.HH"
extern Bool I386RedSeaValid(CI386RedSea *v);
extern Bool I386RedSeaExtent(CI386RedSea *v,I64 block,I64 size);
public I64 I386RedSeaWrite(CI386RedSea *volume,CI386RedSeaEntry *entry,I64 offset,U8 *buffer,I64 count)
{//Raw fixed-extent update. Return confirmed bytes; failed sector may have changed.
  U8 sector[512];
  I64 written=0,n,i,block;
  if (!I386RedSeaValid(volume) || !entry || !buffer || offset<0 || count<0 ||
      (entry->attr&0x311) || !(entry->attr&0x800) ||
      !I386RedSeaExtent(volume,entry->block,entry->size) || offset>entry->size ||
      count>entry->size-offset || count>0xFFFFFFFF ||
      (buffer+0)(U64)>0x100000000-count) return -1;
  while (written<count) {
    block=entry->block+offset/512;
    n=512-(offset&511);
    if (n>count-written) n=count-written;
    if (n!=512 && !I386RedSeaSectorRead(volume,block,sector)) goto fail;
    for (i=0;i<n;i++) sector[(offset&511)+i]=buffer[written+i];
    if (!I386RedSeaSectorWrite(volume,block,sector)) goto fail;
    written+=n; offset+=n;
  }
  return written;
fail:
  if (!written) return -1;
  return written;
}
