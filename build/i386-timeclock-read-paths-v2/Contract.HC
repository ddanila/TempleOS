#include "C:/Apps/TimeClock/Load.HC"
U0 ReportTrace(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool TimeReportCapture(U8 *output)
{
  TimeEntry *entry,*loaded;
  U8 *document;
  I64 bytes;
  Bool ok;
  DocClear;
  ReportTrace("REPORT CAPTURE begin\n");
  if(TimeRep(&loaded)){ReportTrace("REPORT CAPTURE open punch\n");return FALSE;}
  entry=loaded->next;
  ok=entry!=loaded && entry->type==TET_PUNCH_IN && !StrCmp(entry->desc,"start\n") &&
    entry->datetime==730000*0x100000000+0x10000000 && entry->next!=loaded &&
    entry->next->type==TET_PUNCH_OUT && !StrCmp(entry->next->desc,"finish\n") &&
    entry->next->next==loaded && entry->next->datetime==730000*0x100000000+0x20000000;
  if(!ok)ReportTrace("REPORT CAPTURE entry mismatch\n");
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
  if(FileFind(TIME_FILENAME))ReportTrace("REPORT HOME FIND yes\n");
  else ReportTrace("REPORT HOME FIND no\n");
  if(FileFind("C:/Home/TimeClock/TimeFile.DATA.Z"))ReportTrace("REPORT ABS FIND yes\n");
  else ReportTrace("REPORT ABS FIND no\n");
  data=FileRead("C:/Home/TimeClock/TimeFile.DATA.Z",&bytes);
  if(data){ReportTrace("REPORT ABS READ yes\n");Free(data);}
  else ReportTrace("REPORT ABS READ no\n");
  data=FileRead("C:/Packed.DATA.Z",&bytes);
  if(data){ReportTrace("REPORT PACKAGED READ yes\n");Free(data);}
  else ReportTrace("REPORT PACKAGED READ no\n");
  data=FileRead("C:/Archive.DATA",&bytes);
  if(data) {
    U8 *expanded=ExpandBuf(data(CArcCompress *));
    if(expanded){ReportTrace("REPORT DIRECT EXPAND yes\n");Free(expanded);}
    else ReportTrace("REPORT DIRECT EXPAND no\n");
    Free(data);
  } else ReportTrace("REPORT RAW READ no\n");
  data=FileRead(TIME_FILENAME,&bytes);
  if(!data){ReportTrace("REPORT INPUT FileRead failed\n");return FALSE;}
  ReportTrace("REPORT INPUT FileRead passed\n");
  ok=FileWrite("C:/report-records.DATA",data,bytes)>0;
  if(!ok)ReportTrace("REPORT RECORD COPY failed\n");
  Free(data);
  return ok && TimeReportCapture("C:/report-first.DD");
}
