//Run the original application unchanged, including its real GetStr input path.
#include "C:/Apps/TimeClock/Load.HC"
I64 PunchBounds[8];
Bool PunchSave(U8 *name)
{
  I64 bytes;
  U8 *data=FileRead(TIME_FILENAME,&bytes);
  Bool ok;
  if(!data)return FALSE;
  ok=FileWrite(name,data,bytes)>0;
  Free(data);return ok;
}
Bool PunchStage(I64 mode)
{
  TimeEntry *header;
  if(mode==0) {
    header=MAlloc(sizeof(TimeEntry));QueInit(header);
    TimeFileWrite(header);TimeEntriesDel(header);
    PunchOut;return PunchSave("C:/punch-empty.DATA");
  }
  if(mode==1) {
    In("alpha\nbeta\n\x1B");PunchBounds[0]=Now;PunchIn;PunchBounds[1]=Now;
    return PunchSave("C:/punch-in.DATA");
  }
  if(mode==2) {PunchIn;return PunchSave("C:/punch-duplicate-in.DATA");}
  if(mode==3) {
    In("finish\n\x1B");PunchBounds[2]=Now;PunchOut;PunchBounds[3]=Now;
    return PunchSave("C:/punch-out.DATA");
  }
  if(mode==4) {PunchOut;return PunchSave("C:/punch-duplicate-out.DATA");}
  if(mode==5) {
    In("discard\x1C");PunchBounds[4]=Now;PunchIn;PunchBounds[5]=Now;
    return PunchSave("C:/punch-cancel-in.DATA");
  }
  if(mode==6) {
    In("\x1B");PunchBounds[6]=Now;PunchOut;PunchBounds[7]=Now;
    return PunchSave("C:/punch-final.DATA") &&
      FileWrite("C:/punch-bounds.DATA",PunchBounds,sizeof(PunchBounds))>0 && !TimeRep;
  }
  return FALSE;
}
