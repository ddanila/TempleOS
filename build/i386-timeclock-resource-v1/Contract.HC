U0 TimeResourceTrace(U8 *text)
{
  while(*text)OutU8(0xE9,*text++);
}

Bool TimeResourceTrial()
{
  TimeEntry *header=MAlloc(sizeof(TimeEntry)),*entry;
  I64 i,data_before,code_before,data_delta,code_delta,before_bytes,after_bytes;
  U8 *before,*after,*line;
  Bool same;
  QueInit(header);
  entry=CAlloc(sizeof(TimeEntry));entry->type=TET_PUNCH_IN;
  entry->datetime=730000*0x100000000+0x10000000;
  entry->desc=StrNew("start\n");QueIns(entry,header->last);
  entry=CAlloc(sizeof(TimeEntry));entry->type=TET_PUNCH_OUT;
  entry->datetime=730000*0x100000000+0x20000000;
  entry->desc=StrNew("finish\n");QueIns(entry,header->last);
  TimeFileWrite(header);TimeEntriesDel(header);
  before=FileRead(TIME_FILENAME,&before_bytes);
  if(!before || before_bytes!=34)throw('Seed',TRUE);
  TimeRep;
  PunchOut;
  DocClear;
  data_before=Fs->data_heap->used_u8s;
  code_before=Fs->code_heap->used_u8s;
  for(i=0;i<16;i++) {
    if(TimeRep)throw('Open',TRUE);
    PunchOut;
    DocClear;
  }
  data_delta=Fs->data_heap->used_u8s-data_before;
  code_delta=Fs->code_heap->used_u8s-code_before;
  after=FileRead(TIME_FILENAME,&after_bytes);
  same=after && before_bytes==after_bytes && !MemCmp(before,after,before_bytes);
  Free(after);Free(before);
  line=MStrPrint("TIMECLOCK RESOURCE data=%d code=%d same=%d\n",data_delta,code_delta,same);
  TimeResourceTrace(line);Free(line);
  return !data_delta && !code_delta && same;
}
