_extern NativeDriveRecords CDrv *DMDriveRecords;
_extern NativeDriveMap CDrv **DMDriveMap;
CDrv **DMMapSlot(I64 index){return &DMDriveMap[index];}
CDrv *DMRecord(I64 index){return &DMDriveRecords[index];}
Bool DMIdentity(){return DMRecord(Drv2Let()-'A')==Fs->cur_dv&&*DMMapSlot(Drv2Let()-'A')==Fs->cur_dv;}
#include "Contract.HC"
