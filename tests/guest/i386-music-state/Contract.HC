I64 JRContract(I64 unused)
{
  CMusicGlbls saved;I64 mask=0,flags=GetRFlags,i;F64 value,first;
  MemCpy(&saved,&music,sizeof(CMusicGlbls));SetRFlags(flags&~0x200);
  music.play_note_num=9;music.stacatto_factor=0;music.tempo=0;music.octave=1;
  music.note_len=7;music.meter_top=3;music.meter_bottom=8;MusicSettingsRst;
  if(!music.play_note_num && music.stacatto_factor==0.9 && music.tempo==2.5 && music.octave==4 && music.note_len==1 && music.meter_top==4 && music.meter_bottom==4 && !music.last_Beat)mask|=1;
  music.cur_song="Test";music.cur_song_task=Fs;music.mute=3;music.tM_correction=11;
  for(i=0;i<7;i++)music.note_map[i]=6-i;
  MusicSettingsRst;
  Bool ok=music.cur_song_task==Fs && music.mute==3 && music.tM_correction==11 && !StrCmp(music.cur_song,"Test");
  for(i=0;i<7;i++)if(music.note_map[i]!=6-i)ok=FALSE;
  if(ok)mask|=2;
  music.tempo=0;music.last_Beat=7.5;music.last_tM=-1;value=Beat;
  if(value==7.5 && music.last_Beat==7.5 && music.last_tM==tM)mask|=4;
  music.tempo=2;music.last_Beat=7.5;music.last_tM=tM-2;value=Beat;
  if(Abs(value-11.5)<1e-9 && music.last_Beat==value && music.last_tM==tM)mask|=8;
  first=tM;music.tM_correction+=JIFFY_FREQ;value=tM;
  if(Abs(value-first-1)<1e-9)mask|=16;
  Snd(60);MusicSettingsRst;
  if(!(InU8(0x61)&3) && !(GetRFlags&0x200) && !music.last_Beat && music.last_tM==tM)mask|=32;
  MemCpy(&music,&saved,sizeof(CMusicGlbls));SetRFlags(flags);return mask;
}
