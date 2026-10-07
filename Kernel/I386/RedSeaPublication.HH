#ifndef I386_REDSEA_PUBLICATION_INCLUDED
#define I386_REDSEA_PUBLICATION_INCLUDED
#include "/Kernel/I386/RedSea.HH"
#include "/Kernel/I386/ModulePublish.HH"
class CI386RedSeaPublication {
  CI386ModulePublish transaction;
  CI386RedSea *shared,*volume;
  CI386RedSea private_volume;
  I64 sector,old_block,old_blocks;
  U32 slot;
  U8 before[64],after[64];
};
//Caller resolves a regular-file slot and owns its complete-operation disk lease.
extern Bool I386RedSeaPublicationInit(CI386RedSeaPublication *p,CI386RedSea *volume,
  I64 sector,U32 slot,U8 *new_entry,I64 *owned_block);
extern Bool I386RedSeaPublicationCommit(CI386RedSeaPublication *p);
extern Bool I386RedSeaPublicationRecover(CI386RedSeaPublication *p);
#endif
