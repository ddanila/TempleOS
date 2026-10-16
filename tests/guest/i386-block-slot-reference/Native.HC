_extern NativeBlockRecords CBlkDev *BSBlockRecords;
CBlkDev *BSRecord(I64 index){return &BSBlockRecords[index];}
Bool BSIdentity(){I64 i;for(i=0;i<BLKDEVS_NUM;i++)if(BSRecord(i)==Fs->cur_dv->bd)return TRUE;return FALSE;}
#include "Contract.HC"
