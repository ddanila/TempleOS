#ifndef I386_REDSEA_FILE_SESSION_INCLUDED
#define I386_REDSEA_FILE_SESSION_INCLUDED
#include "/Kernel/I386/RedSea.HH"
Bool I386RedSeaBeginFile(CI386RedSea *volume)
{//Whole-file reads/writes match the original unconditional DrvUnlock path.
  if(!I386RedSeaBegin(volume))return FALSE;
  if(volume->public_drive_active)volume->public_drive_unlock=TRUE;
  return TRUE;
}
#endif
