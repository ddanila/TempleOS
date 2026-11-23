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

public F64 FullSaw(F64 t,F64 period)
{//Plus&Minus Sawtooth. 1.0 - -1.0 think "Sin"
  if (period) {
    if (t>=0.0)
      return 2.0*(t%period/period)-1.0;
    else
      return 2.0*(t%period/period)+1.0;
  } else
    return 0.0;
}

public F64 Caw(F64 t,F64 period)
{//Cawtooth. 1.0 - 0.0 think "(Cos+1)/2"
  if (period) {
    if (t>=0.0)
      return 1.0-t%period/period;
    else
      return -(t%period)/period;
  } else
    return 1.0;
}

public F64 FullCaw(F64 t,F64 period)
{//Plus&Minus Cawtooth. 1.0 - -1.0 think "Cos"
  if (period) {
    if (t>=0.0)
      return -2.0*(t%period/period)+1.0;
    else
      return -2.0*(t%period/period)-1.0;
  } else
    return 1.0;
}

public F64 Tri(F64 t,F64 period)
{//Triangle waveform. 0.0 - 1.0 - 0.0
  if (period) {
    t=2.0*(Abs(t)%period)/period;
    if (t<=1.0)
      return t;
    else
      return 2.0-t;
  } else
    return 0.0;
}

public F64 FullTri(F64 t,F64 period)
{//Plus&Minus Triangle waveform. 0.0 - 1.0 - 0.0 - -1.0 -0.0
  if (period) {
    t=4.0*(t%period)/period;
    if (t<=-1.0) {
      if (t<=-3.0)
	return t+4.0;
      else
	return -2.0-t;
    } else {
      if (t<=1.0)
	return t;
      else if (t<=3.0)
	return 2.0-t;
      else
	return t-4.0;
    }
  } else
    return 0.0;
}

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
