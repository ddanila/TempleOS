#include "Contract.HC"
U0 ROReport(U8*s){while(*s)OutU8(0xE9,*s++);}
I64 i;U8 *output,*line;
ROWarm;
for(i=0;i<13;i++){
 output=CAlloc(RO_BYTES);ROCapture(i,output);
 line=MStrPrint("EXPORT raw-output-%d.bin %X %X\n",i,output,RO_BYTES);ROReport(line);Free(line);
}
ROReport("DONE original raw output\n");
