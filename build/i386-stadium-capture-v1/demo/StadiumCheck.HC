U0 StadiumTrace(U8 *p){while(*p)OutU8(0xE9,*p++);}
U0 StadiumCopy(U8 *source,U8 *target)
{
  I64 size;
  U8 *bytes=FileRead(source,&size);
  if(!bytes || size<=0)throw('StadCopy',TRUE);
  FileWrite(target,bytes,size);
  Free(bytes);Free(source);Free(target);
}
U0 StadiumCheck(U8 *source,U8 *target)
{
  U8 *file,*line;
  CDC *saved;
  DirMk(target);
  StadiumCopy(MStrPrint("%s/StadiumGen.HC",source),MStrPrint("%s/StadiumGen.HC",target));
  StadiumCopy(MStrPrint("%s/StadiumBG.DD",source),MStrPrint("%s/StadiumBG.DD",target));
  StadiumTrace("STADIUM GENERATOR START\n");
  file=MStrPrint("%s/StadiumGen.HC",target);
  ExeFile(file);
  Free(file);
  file=MStrPrint("%s/StadiumBG",target);
  saved=GRRead(file);
  Free(file);
  if(!saved || saved->width!=641 || saved->height!=473)
    throw('Stadium',TRUE);
  line=MStrPrint("EXPORT stadium.raw %X %X\n",saved->body,saved->width_internal*saved->height);
  StadiumTrace(line);
  Sleep(1000);
  Free(line);DCDel(saved);
  StadiumTrace("STADIUM GENERATOR DONE\n");
}
StadiumTrace("STADIUM READY\n");
