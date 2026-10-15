U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Form.HC"
I64*v=CAlloc(504),i;U8*line;
for(i=0;i<7;i++){line=MStrPrint("FORM begin %d\n",i);Report(line);Free(line);v[i]=FPContract(i);v[i+7]=fp_heap_delta[i];v[i+14]=fp_root_delta[i];v[i+21]=fp_bound[i];v[i+28]=fp_seen_each[i];v[i+35]=fp_name_len[i];v[i+42]=fp_name_raw[i];v[i+49]=fp_windows[i];v[i+56]=FPYieldControl;}
line=MStrPrint("EXPORT class-form.bin %X %X\n",v,504);Report(line);Free(line);Report("DONE original class forms\n");
