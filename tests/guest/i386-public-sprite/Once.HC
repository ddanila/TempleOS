U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/PublicSprite.HC"
I64 result=PublicSpriteContract;U8 *line=MStrPrint("PUBLIC SPRITE MASK %d\n",result);
Report(line);Free(line);Report("DONE public sprite\n");
