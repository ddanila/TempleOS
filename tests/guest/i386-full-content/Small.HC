U0 FCMark(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool FCFile(U8 *name,I64 expected)
{
  CDirEntry e;Bool ok=FileFind(name,&e,FUF_JUST_FILES);
  if(ok) {ok=e.size==expected;Free(e.full_name);}
  return ok;
}
I64 FullContentContract()
{
  I64 mask=0,size=0,base=Fs->data_heap->used_u8s;U8 *data;
  FCMark("FC apps\n");
  if(FCFile("C:/Apps/TimeClock/Load.HC",119))mask|=1;
  FCMark("FC demo\n");
  if(FCFile("C:/Demo/Games/Stadium/StadiumBG.DD",302127))mask|=2;
  FCMark("FC bible stat\n");
  if(FCFile("C:/Misc/Bible.TXT",4345143))mask|=4;
  FCMark("FC dictionary stat\n");
  if(FCFile("C:/Adam/AutoComplete/ACDefs.DATA",26381073))mask|=8;
  FCMark("FC app read begin\n");
  data=FileRead("C:/Apps/TimeClock/Load.HC",&size);
  FCMark("FC app read end\n");
  if(data && size==119)mask|=16;
  Free(data);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
