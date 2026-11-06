U0 MRLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 MRCheck()
{
  CMusicGlbls saved;
  I64 i,mask=0,values[5];F64 floats[4];U8 *s;
  MemCpy(&saved,&music,sizeof(CMusicGlbls));
  music.cur_song="reset sentinel";music.cur_song_task=Fs;
  music.mute=TRUE;music.tM_correction=17.25;
  for(i=0;i<7;i++)music.note_map[i]=i+11;
  music.play_note_num=99;music.stacatto_factor=0.2;music.tempo=7.0;
  music.octave=8;music.note_len=3.0;music.meter_top=7;music.meter_bottom=8;
  music.last_Beat=11.0;music.last_tM=-9.0;
  MusicSettingsRst;
  if(!StrCmp(music.cur_song,"reset sentinel"))mask|=1;
  if(music.cur_song_task==Fs)mask|=2;
  if(music.mute)mask|=4;
  if(music.tM_correction==17.25)mask|=8;
  for(i=0;i<7;i++)if(music.note_map[i]!=i+11)break;
  if(i==7)mask|=16;
  if(music.last_tM>=0.0)mask|=32;
  values[0]=music.play_note_num;values[1]=music.octave;
  values[2]=music.meter_top;values[3]=music.meter_bottom;values[4]=mask;
  floats[0]=music.stacatto_factor;floats[1]=music.tempo;
  floats[2]=music.note_len;floats[3]=music.last_Beat;
  s=MStrPrint("EXPORT values.bin %X %X\n",values,sizeof(values));MRLog(s);Free(s);
  s=MStrPrint("EXPORT floats.bin %X %X\n",floats,sizeof(floats));MRLog(s);Free(s);
  MemCpy(&music,&saved,sizeof(CMusicGlbls));
  MRLog("MUSIC RESET DONE\n");Sleep(1000);
}
