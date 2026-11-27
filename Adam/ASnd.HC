#help_index "Snd"
public U0 SndTaskEndCB()
{//Will turn-off snd when a task gets killed.
  Snd;
  Exit;
}

#help_index "Snd/Math;Math"
public F64 Saw(F64 t,F64 period)
{//Sawtooth. 0.0 - 1.0 think "(Sin+1)/2"
  if (period) {
    if (t>=0.0)
      return t%period/period;
    else
      return 1.0+t%period/period;
  } else
    return 0.0;
}

#include "/Adam/Snd/WaveformCore.HC"

#help_index "Snd/Music"

#include "/Adam/MusicStateCore.HC"

#help_index "Snd/Music"
#include "/Adam/Snd/NoteConversionCore.HC"

#include "/Adam/Snd/MusicPlayCore.HC"

#include "/Adam/MusicResetCore.HC"

MusicSettingsRst;

U0 CurSongTask()
{
  Fs->task_end_cb=&SndTaskEndCB;
  while (TRUE)
    Play(music.cur_song);
}

#help_index "Snd"

#include "/Adam/Snd/SndEffects.HC"
