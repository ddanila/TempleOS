#include "C:/Apps/TimeClock/Load.HC"
Bool TimeReportCapture(U8 *output)
{
  TimeEntry *entry,*loaded;
  U8 *document;
  I64 bytes;
  Bool ok;
  DocClear;
  if(TimeRep(&loaded))return FALSE;
  entry=loaded->next;
  ok=entry!=loaded && entry->type==TET_PUNCH_IN && !StrCmp(entry->desc,"start\n") &&
    entry->datetime==730000*0x100000000+0x10000000 && entry->next!=loaded &&
    entry->next->type==TET_PUNCH_OUT && !StrCmp(entry->next->desc,"finish\n") &&
    entry->next->next==loaded && entry->next->datetime==730000*0x100000000+0x20000000;
  TimeEntriesDel(loaded);
  document=DocSave(DocPut,&bytes);
  if(!document)return FALSE;
  ok=ok && FileWrite(output,document,bytes)>0;
  Free(document);return ok;
}
Bool TimeReportSeed()
{
  TimeEntry *header=MAlloc(sizeof(TimeEntry)),*entry;
  U8 *data;
  I64 bytes;
  Bool ok;
  QueInit(header);
  entry=CAlloc(sizeof(TimeEntry));entry->type=TET_PUNCH_IN;
  entry->datetime=730000*0x100000000+0x10000000;
  entry->desc=StrNew("start\n");QueIns(entry,header->last);
  entry=CAlloc(sizeof(TimeEntry));entry->type=TET_PUNCH_OUT;
  entry->datetime=730000*0x100000000+0x20000000;
  entry->desc=StrNew("finish\n");QueIns(entry,header->last);
  TimeFileWrite(header);TimeEntriesDel(header);
  data=FileRead(TIME_FILENAME,&bytes);
  if(!data)return FALSE;
  ok=FileWrite("C:/report-records.DATA",data,bytes)>0;
  Free(data);
  return ok && TimeReportCapture("C:/report-first.DD");
}
