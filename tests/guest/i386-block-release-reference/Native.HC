_extern NativeDriveRecords CDrv *BRDriveRecords;
CDrv *BRRecord(I64 index){return &BRDriveRecords[index];}
#include "Contract.HC"
_extern NativeBlockRecords CBlkDev *BRBlockRecords;
CBlkDev *BRBlockRecord(I64 index){return &BRBlockRecords[index];}
#include "Table.HC"
