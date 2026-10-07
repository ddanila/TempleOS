#ifndef MUSIC_JIFFIES
#define MUSIC_JIFFIES cnts.jiffies
#endif
U64 MusicClockLock()
{
#ifdef MUSIC_NATIVE_SINGLE_CPU
  return I386IrqSave;
#else
  U64 flags=GetRFlags;
  SetRFlags(flags&~0x200);
  if(mp_cnt>1)
    while(LBts(&sys_semas[SEMA_TMBEAT],0)) {
      PAUSE
    }
  return flags;
#endif
}
U0 MusicClockUnlock(U64 flags)
{
#ifdef MUSIC_NATIVE_SINGLE_CPU
  I386IrqRestore(flags);
#else
  LBtr(&sys_semas[SEMA_TMBEAT],0);
  SetRFlags(flags);
#endif
}
public class CMusicGlbls
{
  U8	*cur_song;
  CTask	*cur_song_task;
  I64	octave;
  F64	note_len;
  U8	note_map[7];
  Bool	mute;
  I64	meter_top,meter_bottom;
  F64	tempo,stacatto_factor;

  //If you wish to sync with a
  //note in a Play() string.  0 is the start
  I64	play_note_num;

  F64	tM_correction,last_Beat,last_tM;
} music={NULL,NULL,4,1.0,{0,2,3,5,7,8,10},FALSE,4,4,2.5,0.9,0,0,0,0};

#help_index "Snd/Music;Time/Seconds"
public F64 tM()
{//Time in seconds synced to music subsystem.
  return (MUSIC_JIFFIES+music.tM_correction)/JIFFY_FREQ;
}

public F64 Beat()
{//Time in music beats.
  F64 res,cur_tM;
  U64 flags;
  flags=MusicClockLock;
  cur_tM=tM;
  res=music.last_Beat;
  if (music.tempo)
    res+=(cur_tM-music.last_tM)*music.tempo;
  music.last_tM=cur_tM;
  music.last_Beat=res;
  MusicClockUnlock(flags);
  return res;
}

