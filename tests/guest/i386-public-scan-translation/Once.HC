U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/KeyTranslate.HC"
U8 *line;if(!BuildKeyTable){Report("FAIL key translation\n");throw;}
line=MStrPrint("EXPORT keys.bin %X %X\n",key_table,KEY_TABLE_BYTES);Report(line);Free(line);
Report("DONE key translation\n");
