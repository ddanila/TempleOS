U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/Clipboard.HC"
I64 *v=CAlloc(88),i;for(i=0;i<6;i++){OutU8(0xE9,'0'+i);Report(" CLIP begin\n");v[i]=CLContract(i);Report("CLIP end\n");}
v[6]=CLWorkerContract;v[7]=cl_control_caller;v[8]=cl_control_clip;v[9]=cl_caller_delta;v[10]=cl_clip_delta;
U8 *obs=MStrPrint("OBS clipboard heaps %d %d control %d %d\n",cl_caller_delta,cl_clip_delta,cl_control_caller,cl_control_clip);Report(obs);Free(obs);
U8 *line=MStrPrint("EXPORT clipboard.bin %X %X\n",v,88);Report(line);Free(line);
Report("DONE original clipboard\n");
