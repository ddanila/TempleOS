U0 WriteReadTrace(U8 *line)
{
  while(*line)OutU8(0xE9,*line++);
}

U0 CheckFreshFile(U8 *path,U8 *record,I64 size)
{
  U8 *copy;
  I64 bytes;
  WriteReadTrace(path);
  if(!FileWrite(path,record,size)) {
    WriteReadTrace(" WRITE failed\n");
    return;
  }
  copy=FileRead(path,&bytes);
  if(!copy)WriteReadTrace(" READ missing\n");
  else if(bytes!=size || MemCmp(copy,record,size))WriteReadTrace(" READ differs\n");
  else WriteReadTrace(" READ exact\n");
  Free(copy);
}

U0 CheckFreshArchive()
{
  I64 bytes;
  U8 *archive=FileRead("C:/Archive.DATA",&bytes);
  U8 *record;
  if(!archive)throw('Archive',TRUE);
  bytes=archive(CArcCompress *)->expanded_size;
  record=ExpandBuf(archive(CArcCompress *));
  Free(archive);
  if(!record || bytes!=34)throw('Record',TRUE);
  CheckFreshFile("~/TimeClock/TimeFile.DATA.Z",record,bytes);
  CheckFreshFile("~/TimeClock/TimeFile.DATA.Z",record,bytes);
  CheckFreshFile("C:/Fresh/Plain/First.DATA",record,bytes);
  CheckFreshFile("C:/Fresh/Plain/First.DATA",record,bytes);
  CheckFreshFile("C:/Fresh/Packed/First.DATA.Z",record,bytes);
  CheckFreshFile("C:/Fresh/Packed/First.DATA.Z",record,bytes);
  if(!DirMk("C:/Explicit"))throw('Dir',TRUE);
  CheckFreshFile("C:/Explicit/First.DATA.Z",record,bytes);
  Free(record);
}
CheckFreshArchive;
