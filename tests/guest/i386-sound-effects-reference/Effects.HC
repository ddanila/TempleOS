I64 SFContract()
{
  I64 mask=0,old=music.mute;F64 limit;CTask *task;Bool heard;
  Snd;
  if(!Noise(0,74,74) && !Sweep(-1,60,72) && music.mute==old)mask|=1;
  task=Noise(350,74,74);
  if(task && music.mute==old+1)mask|=2;
  heard=FALSE;limit=tS+4;
  while(music.mute!=old && tS<limit){if((InU8(0x61)&3)==3)heard=TRUE;Sleep(5);}
  if(heard && music.mute==old && (InU8(0x61)&3)==0)mask|=4;
  task=Sweep(350,60,72);
  if(task && music.mute==old+1)mask|=8;
  heard=FALSE;limit=tS+4;
  while(music.mute!=old && tS<limit){if((InU8(0x61)&3)==3)heard=TRUE;Sleep(5);}
  if(heard && music.mute==old && (InU8(0x61)&3)==0)mask|=16;
  task=Noise(5000,74,74);limit=tS+4;
  if(task) {
    while(!FramePtr("CSoundEffectFrame",task) && tS<limit)Sleep(5);
    if(FramePtr("CSoundEffectFrame",task)) {
      Kill(task,TRUE);
      if(music.mute==old && (InU8(0x61)&3)==0)mask|=32;
    }
  }
  Snd;return mask;
}
I64 SFCheck(){I64 v=SFContract;if(v!=63)throw('SoundFX',TRUE);return v;}
