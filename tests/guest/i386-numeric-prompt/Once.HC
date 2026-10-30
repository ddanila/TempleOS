U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/NumericPrompt.HC"
I64 result=NumericPromptContract;U8 *line=MStrPrint("NUMERIC PROMPT MASK %d\n",result);
Report(line);Free(line);line=MStrPrint("FLOAT BITS %X\n",prompt_float_bits);Report(line);Free(line);Report("DONE numeric prompt\n");
