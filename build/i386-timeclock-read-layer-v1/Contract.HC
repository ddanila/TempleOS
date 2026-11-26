#include "C:/Apps/TimeClock/Load.HC"

U0 SequenceTrace(U8 *line)
{
  while(*line)OutU8(0xE9,*line++);
}

U0 SequenceCheck(U8 *stage,U8 *path,U8 *expected,I64 size)
{
  I64 bytes;
  U8 *actual=FileRead(path,&bytes);
  SequenceTrace("SEQUENCE ");
  SequenceTrace(stage);
  if(!actual)SequenceTrace(" missing\n");
  else if(bytes!=size || MemCmp(actual,expected,size))
    SequenceTrace(" differs\n");
  else SequenceTrace(" exact\n");
  Free(actual);
}

U0 SequenceRawCheck(U8 *archive,I64 bytes)
{
  CDirEntry entry;
  CDrv *drive=Let2Drv('C');
  U8 *sector=MAlloc(512);
  if(!FileFind(TIME_FILENAME,&entry))
    SequenceTrace("SEQUENCE directory entry missing\n");
  else {
    if(entry.size!=bytes || entry.attr!=0xC00)
      SequenceTrace("SEQUENCE directory metadata differs\n");
    else SequenceTrace("SEQUENCE directory metadata exact\n");
    if(!BlkRead(drive,sector,Clus2Blk(drive,entry.clus),1))
      SequenceTrace("SEQUENCE raw sector read failed\n");
    else if(MemCmp(sector,archive,bytes))
      SequenceTrace("SEQUENCE raw archive differs\n");
    else SequenceTrace("SEQUENCE raw archive exact\n");
    Free(entry.full_name);
  }
  Free(sector);
}

U0 CheckTimeWriteSequence()
{
  TimeEntry *header=MAlloc(sizeof(TimeEntry)),*entry;
  I64 bytes,packed;
  U8 *archive=FileRead("C:/Archive.DATA",&packed);
  U8 *expected;
  if(!archive)throw('Archive',TRUE);
  bytes=archive(CArcCompress *)->expanded_size;
  expected=ExpandBuf(archive(CArcCompress *));
  if(!expected || bytes!=34)throw('Record',TRUE);

  QueInit(header);
  entry=CAlloc(sizeof(TimeEntry));entry->type=TET_PUNCH_IN;
  entry->datetime=730000*0x100000000+0x10000000;
  entry->desc=StrNew("start\n");QueIns(entry,header->last);
  entry=CAlloc(sizeof(TimeEntry));entry->type=TET_PUNCH_OUT;
  entry->datetime=730000*0x100000000+0x20000000;
  entry->desc=StrNew("finish\n");QueIns(entry,header->last);
  TimeFileWrite(header);
  SequenceCheck("application write",TIME_FILENAME,expected,bytes);
  TimeEntriesDel(header);
  SequenceCheck("after cleanup",TIME_FILENAME,expected,bytes);
  SequenceCheck("absolute read after cleanup","C:/Home/TimeClock/TimeFile.DATA.Z",expected,bytes);
  SequenceRawCheck(archive,packed);
  SequenceCheck("after raw sector read",TIME_FILENAME,expected,bytes);
  if(!FileWrite(TIME_FILENAME,expected,bytes))throw('Write',TRUE);
  SequenceCheck("direct replacement",TIME_FILENAME,expected,bytes);
  Free(archive);
  Free(expected);
}
