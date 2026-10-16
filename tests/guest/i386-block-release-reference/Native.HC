_extern NativeDriveRecords CDrv *BRDriveRecords;
CDrv *BRRecord(I64 index){return &BRDriveRecords[index];}
#include "Contract.HC"
