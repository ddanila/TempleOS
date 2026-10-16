_extern NativeDriveMap CDrv **SPDriveMap;
CDrv **SPMapSlot(I64 index){return &SPDriveMap[index];}
#include "Contract.HC"
