#ifndef I386_PUBLIC_SOUND_INCLUDED
#define I386_PUBLIC_SOUND_INCLUDED
#include "/Adam/MusicTypes.HH"
#help_index "Snd"
public _extern _ONA_2_FREQ F64 Ona2Freq(I8 ona);
public _extern _NOISE CTask *Noise(I64 mS,F64 min_ona,F64 max_ona);
public _extern _SWEEP CTask *Sweep(I64 mS,F64 ona1,F64 ona2);
public _extern _MUSIC_GLOBALS CMusicGlbls music;
public _extern _BEEP U0 Beep(I8 ona=62,Bool busy=FALSE);
public _extern _SND U0 Snd(I8 ona=0);
public _extern _SND_RST U0 SndRst();
#endif
