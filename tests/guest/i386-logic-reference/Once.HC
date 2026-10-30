//Exercise unchanged Logic synthesis on concrete truth tables.
U0 Report(U8 *s) {while(*s)OutU8(0xE9,*s++);}
#include "T:/Apps/Logic/Load.HC"
I64 LogicCase(I64 gate,I64 result,I64 inputs)
{
  I64 found,ok;
  table_size=256;num_outputs_entered=1;num_sel_gates=1;sel_gates[0]=gate;
  gate_type_table=CAlloc(table_size);displayed_design=CAlloc(32);
  added_this_pass=CAlloc(32);input1_table=CAlloc(table_size*sizeof(U16));
  input2_table=CAlloc(table_size*sizeof(U16));input3_table=CAlloc(table_size*sizeof(U16));
  gate_type_table[0xF0]=GT_INPUT;input1_table[0xF0]=0;
  if(inputs>1){gate_type_table[0xCC]=GT_INPUT;input1_table[0xCC]=1;}
  if(inputs>2){gate_type_table[0xAA]=GT_INPUT;input1_table[0xAA]=2;}
  gate_type_table[result]=GT_OUTPUT;
  found=FillGateTable;
  ok=found==1 && output_found==result && gate_type_table[result]==gate && passes==2;
  if(gate==GT_NOT)ok=ok && input1_table[result]==0xF0;
  else if(inputs==2)ok=ok && ((input1_table[result]==0xF0 && input2_table[result]==0xCC) ||
      (input1_table[result]==0xCC && input2_table[result]==0xF0));
  else ok=ok && (input1_table[result]&input2_table[result]&input3_table[result])==0x80;
  CleanUp;return ok;
}
I64 LogicReference()
{
  I64 m=0;
  if(LogicCase(GT_NOT,0x0F,1))m|=1;
  if(LogicCase(GT_AND,0xC0,2))m|=2;
  if(LogicCase(GT_OR,0xFC,2))m|=4;
  if(LogicCase(GT_NAND,0x3F,2))m|=8;
  if(LogicCase(GT_NOR,0x03,2))m|=16;
  if(LogicCase(GT_XOR,0x3C,2))m|=32;
  if(LogicCase(GT_AND3,0x80,3))m|=64;
  if(LogicCase(GT_OR3,0xFE,3))m|=128;
  if(LogicCase(GT_NAND3,0x7F,3))m|=256;
  if(LogicCase(GT_NOR3,0x01,3))m|=512;
  return m;
}
I64 result=LogicReference;U8 *line=MStrPrint("LOGIC MASK %d\n",result);
Report(line);Free(line);Report("DONE original Logic synthesis\n");
