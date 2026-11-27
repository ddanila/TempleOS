U0 ReverseFileCapture()
{
  I64 bytes;
  U8 *data=FileRead("~/DemoPoemFwd.DD.Z",&bytes),*line,*cursor;
  if (!data)
    return;
  line=MStrPrint("EXPORT DemoPoemFwd.DD %X %X\n",data,bytes);
  cursor=line;
  while (*cursor) OutU8(0xE9,*cursor++);
  Sleep(1000);
  Free(line);
  Free(data);
  line="DONE reverse file\n";
  while (*line) OutU8(0xE9,*line++);
}
ReverseFileCapture;
