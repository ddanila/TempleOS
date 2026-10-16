_extern NativeDriveRecords CDrv *DSDriveRecords;
CDrv *DSRecord(I64 index){return &DSDriveRecords[index];}
Bool DSIdentity(){return DSRecord(Drv2Let()-'A')==Fs->cur_dv;}
#include "Contract.HC"
