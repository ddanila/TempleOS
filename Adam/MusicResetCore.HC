U0 MusicSettingsRst()
{
  U64 flags;
  music.play_note_num=0;
  music.stacatto_factor=0.9;
  music.tempo=2.5;
  music.octave=4;
  music.note_len=1.0;
  music.meter_top=4;
  music.meter_bottom=4;
  SndRst;
  flags=MusicClockLock;
  music.last_tM=tM;
  music.last_Beat=0.0;
  MusicClockUnlock(flags);
}

