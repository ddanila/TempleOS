while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
#include "T:/Apps/Psalmody/Run"
U0 PLReturn(I64 a,I64 b){U8 *s=MStrPrint("PSALMODY RETURN %d\n",a*b),*ptr=s;while(*ptr)OutU8(0xE9,*ptr++);Free(s);}
PLReturn(6,7);
