#define MUSIC_JIFFIES ToI64(Round(tS*1000.0))
#include "/Adam/Snd/MusicPlayCore.HC"
public U0 SndTaskEndCB()
{//Will turn-off snd when a task gets killed.
  Snd;
  Exit;
}
