I64 SNSmall()
{
  I64 old=music.mute,seen=0;F64 limit=tS+4;CTask *task=Noise(350,74,74);
  if(!task)return 0;
  while(music.mute!=old && tS<limit) {
    if((InU8(0x61)&3)==3)seen=1;
    Sleep(5);
  }
  return seen && music.mute==old && (InU8(0x61)&3)==0;
}
