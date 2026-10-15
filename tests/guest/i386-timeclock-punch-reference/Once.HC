//Unchanged application and real GetStr; In feeds the original input path.
U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }
Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");
#include "T:/Apps/TimeClock/Load.HC"
I64 punch_bounds[8];
U0 ExportPunch(U8 *name)
{
  I64 size;
  U8 *data=FileRead(TIME_FILENAME,&size),*line;
  if(!data) {Report("FAIL TimeClock missing punch file\n");return;}
  line=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(line);Free(line);
}
U0 PunchReference()
{
  TimeEntry *header=MAlloc(sizeof(TimeEntry));
  U8 *line;
  //Seed a genuine empty application file, avoiding missing-file diagnostics.
  QueInit(header);TimeFileWrite(header);TimeEntriesDel(header);
  PunchOut;ExportPunch("empty-out.DATA");
  In("alpha\nbeta\n\x1B");punch_bounds[0]=Now;PunchIn;punch_bounds[1]=Now;
  ExportPunch("in.DATA");
  PunchIn;ExportPunch("duplicate-in.DATA");
  In("finish\n\x1B");punch_bounds[2]=Now;PunchOut;punch_bounds[3]=Now;
  ExportPunch("out.DATA");
  PunchOut;ExportPunch("duplicate-out.DATA");
  In("discard\x1C");punch_bounds[4]=Now;PunchIn;punch_bounds[5]=Now;
  ExportPunch("cancel-in.DATA");
  In("\x1B");punch_bounds[6]=Now;PunchOut;punch_bounds[7]=Now;
  ExportPunch("final.DATA");
  DocClear;
  if(TimeRep) {Report("FAIL TimeClock final report is open\n");return;}
  line=MStrPrint("EXPORT bounds.bin %X %X\n",punch_bounds,sizeof(punch_bounds));
  Report(line);Free(line);
  Report("DONE original TimeClock punch commands\n");
}
PunchReference;
