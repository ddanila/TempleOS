//Reference capture only, in a disposable original-system guest.
U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }
Cd("B:/");
DirMk("B:/Home");
HomeSet("B:/Home");
#include "T:/Apps/TimeClock/Load.HC"
U0 TimeClockReference()
{
  TimeEntry *header=MAlloc(sizeof(TimeEntry)),*entry,*loaded;
  U8 *data,*line,*document;
  I64 size,doc_size;
  QueInit(header);
  entry=CAlloc(sizeof(TimeEntry)); entry->type=TET_PUNCH_IN;
  entry->datetime=730000*0x100000000+0x10000000;
  entry->desc=StrNew("start\n"); QueIns(entry,header->last);
  entry=CAlloc(sizeof(TimeEntry)); entry->type=TET_PUNCH_OUT;
  entry->datetime=730000*0x100000000+0x20000000;
  entry->desc=StrNew("finish\n"); QueIns(entry,header->last);
  TimeFileWrite(header); TimeEntriesDel(header);
  data=FileRead(TIME_FILENAME,&size);
  if(!data) { Report("FAIL TimeClock persisted file\n"); return; }
  DocClear;
  if(TimeRep(&loaded)) { Report("FAIL TimeClock closed report\n"); return; }
  entry=loaded->next;
  if(entry==loaded || entry->type!=TET_PUNCH_IN || StrCmp(entry->desc,"start\n") ||
      entry->datetime!=730000*0x100000000+0x10000000 ||
      entry->next==loaded || entry->next->type!=TET_PUNCH_OUT ||
      StrCmp(entry->next->desc,"finish\n") || entry->next->next!=loaded ||
      entry->next->datetime!=730000*0x100000000+0x20000000) {
    Report("FAIL TimeClock reopened entries\n"); return;
  }
  TimeEntriesDel(loaded);
  document=DocSave(DocPut,&doc_size);
  line=MStrPrint("EXPORT TimeClock.DATA %X %X\n",data,size); Report(line); Free(line);
  line=MStrPrint("EXPORT TimeClockReport.DD %X %X\n",document,doc_size); Report(line); Free(line);
  Report("DONE original TimeClock storage and report\n");
}
TimeClockReference;
