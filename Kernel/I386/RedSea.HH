#ifndef I386_REDSEA_INCLUDED
#define I386_REDSEA_INCLUDED
#include "/Kernel/I386/Ata.HH"
class CI386RedSeaIo {
  U8 *context;
  Bool (*begin)(U8 *context);
  Bool (*end)(U8 *context);
  Bool (*read)(U8 *context,CI386Ata *disk,I64 block,U8 *buffer);
  Bool (*write)(U8 *context,CI386Ata *disk,I64 block,U8 *buffer);
  Bool (*flush)(U8 *context,CI386Ata *disk);
};
class CI386RedSea {
  CI386Ata *disk;
  U32 signature;
  I64 start,sectors,first,root;
  CI386RedSeaIo *io;
};
class CI386RedSeaEntry {
  U16 attr;
  U8 name[38];
  I64 block,size,datetime;
};
//Unbound volumes retain boot-owned quiescent I/O. Bound volumes require a session
//around the complete metadata/data operation; callbacks and context stay live.
public extern Bool I386RedSeaValid(CI386RedSea *volume);
extern Bool I386RedSeaDecode(CI386RedSea *volume,U8 *raw,CI386RedSeaEntry *entry);
public extern Bool I386RedSeaBegin(CI386RedSea *volume);
public extern Bool I386RedSeaEnd(CI386RedSea *volume);
public extern Bool I386RedSeaSectorRead(CI386RedSea *volume,I64 block,U8 *buffer);
public extern Bool I386RedSeaSectorWrite(CI386RedSea *volume,I64 block,U8 *buffer);
public extern Bool I386RedSeaFlush(CI386RedSea *volume);
public extern Bool I386RedSeaMount(CI386RedSea *volume,CI386Ata *disk,I64 start);
public extern I64 I386RedSeaFind(CI386RedSea *volume,I64 directory,U8 *name,CI386RedSeaEntry *entry);
public extern I64 I386RedSeaRead(CI386RedSea *volume,CI386RedSeaEntry *entry,I64 offset,U8 *buffer,I64 count);
public extern I64 I386RedSeaWrite(CI386RedSea *volume,CI386RedSeaEntry *entry,I64 offset,U8 *buffer,I64 count);
public extern I64 I386RedSeaAlloc(CI386RedSea *volume,I64 count);
public extern Bool I386RedSeaFree(CI386RedSea *volume,I64 block,I64 count);
public extern I64 I386RedSeaCreate(CI386RedSea *volume,I64 directory,U8 *name,U8 *buffer,I64 size,I64 datetime=0,I64 attr=0x800);
public extern I64 I386RedSeaDelete(CI386RedSea *volume,I64 directory,U8 *name);
public extern I64 I386RedSeaRename(CI386RedSea *volume,I64 directory,U8 *old_name,U8 *new_name);
public extern I64 I386RedSeaDirDelete(CI386RedSea *volume,I64 directory,U8 *name);
public extern I64 I386RedSeaReplace(CI386RedSea *volume,I64 directory,U8 *name,U8 *buffer,I64 size,I64 datetime=0);
//Caller-owned zeroable scratch, one byte per on-disk bitmap byte. Reconcile only
//after a successful mount and before publishing the volume to allocators.
public extern Bool I386RedSeaRepairBitmap(CI386RedSea *volume,U8 *scratch,I64 bytes);
public extern Bool I386RedSeaMoveIntentSet(CI386RedSea *volume,I64 source_parent,Bool source_root,
  U8 *source_name,I64 destination_parent,Bool destination_root,U8 *destination_name,
  CI386RedSeaEntry *source);
public extern Bool I386RedSeaMoveIntentClear(CI386RedSea *volume);
extern Bool I386RedSeaMoveRecover(CI386RedSea *volume);
//1 found, 0 absent, -1 invalid/I/O failure. Resolve absolute or directory-relative slash paths.
public extern I64 I386RedSeaResolve(CI386RedSea *volume,I64 directory,U8 *path,CI386RedSeaEntry *entry);
#endif
