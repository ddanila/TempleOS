#ifndef I386_REDSEA_INCLUDED
#define I386_REDSEA_INCLUDED
#include "/Kernel/I386/Ata.HH"
class CI386RedSea {
  CI386Ata *disk;
  U32 signature;
  I64 start,sectors,first,root;
};
class CI386RedSeaEntry {
  U16 attr;
  U8 name[38];
  I64 block,size,datetime;
};
public extern Bool I386RedSeaMount(CI386RedSea *volume,CI386Ata *disk,I64 start);
public extern I64 I386RedSeaFind(CI386RedSea *volume,I64 directory,U8 *name,CI386RedSeaEntry *entry);
public extern I64 I386RedSeaRead(CI386RedSea *volume,CI386RedSeaEntry *entry,I64 offset,U8 *buffer,I64 count);
public extern I64 I386RedSeaWrite(CI386RedSea *volume,CI386RedSeaEntry *entry,I64 offset,U8 *buffer,I64 count);
public extern I64 I386RedSeaAlloc(CI386RedSea *volume,I64 count);
public extern Bool I386RedSeaFree(CI386RedSea *volume,I64 block,I64 count);
public extern I64 I386RedSeaCreate(CI386RedSea *volume,I64 directory,U8 *name,U8 *buffer,I64 size,I64 datetime=0);
public extern I64 I386RedSeaDelete(CI386RedSea *volume,I64 directory,U8 *name);
public extern I64 I386RedSeaReplace(CI386RedSea *volume,I64 directory,U8 *name,U8 *buffer,I64 size,I64 datetime=0);
#endif
