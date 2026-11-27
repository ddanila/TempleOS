//0 no nothing
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.901;
  try {
    while (!ScanKey) {
	Play("5hCD");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
