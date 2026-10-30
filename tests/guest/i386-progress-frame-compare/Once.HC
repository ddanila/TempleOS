U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/ProgressCompare.HC"
I64 i;U8 *line;
CaptureProgressFrames;
for(i=0;i<4;i++){line=MStrPrint("EXPORT frame%d.bin %X %X\n",i,progress_frames[i],640*480);Report(line);Free(line);}
Report("DONE progress comparison\n");
