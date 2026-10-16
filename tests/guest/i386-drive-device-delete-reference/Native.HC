_extern NativeDriveRecords CDrv *DBDriveRecords;
CDrv *DBRecord(I64 index){return &DBDriveRecords[index];}
#include "Contract.HC"
