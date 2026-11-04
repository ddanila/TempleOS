U0 EspReport(U8 *text)
{ while(*text)OutU8(0xE9,*text++); }
U0 EspReserve(CI386Out *out,I64 minimum)
{ throw('Compiler'); }
U0 EspContract()
{
  U32 offsets[9];
  U8 opcodes[3],buffer[16],hex[33],*digits="0123456789ABCDEF",*line;
  CI386Out *sink=CAlloc(sizeof(CI386Out));
  I64 i,j,register_index,k,count;
  Bool rejected=FALSE;
  offsets[0]=0;offsets[1]=1;offsets[2]=127;offsets[3]=128;
  offsets[4]=0xFFFFFF7F;offsets[5]=0xFFFFFF80;offsets[6]=0xFFFFFFFF;
  offsets[7]=0x7FFFFFFF;offsets[8]=0x80000000;
  opcodes[0]=0x8B;opcodes[1]=0x89;opcodes[2]=0xFF;
  for(i=0;i<9;i++)for(j=0;j<3;j++)for(register_index=0;register_index<8;register_index++) {
    if(j!=2 || register_index==2) {
    MemSet(sink,0,sizeof(CI386Out));
    sink->data=buffer;sink->capacity=16;sink->reserve=&EspReserve;
    I386EspMemory(sink,opcodes[j],register_index,offsets[i]);count=sink->count;
    for(k=0;k<count;k++) {
      hex[2*k]=digits[buffer[k]>>4];hex[2*k+1]=digits[buffer[k]&15];
    }
    hex[2*count]=0;
    sink->count=0;sink->measuring=TRUE;
    I386EspMemory(sink,opcodes[j],register_index,offsets[i]);
    line=MStrPrint("OBS ESP %X %d %X %d %d %s\n",opcodes[j],register_index,offsets[i],count,sink->count,hex);
    EspReport(line);Free(line);
    }
  }
  sink->count=0;sink->measuring=FALSE;
  try { I386EspMemory(sink,0x8B,8,0); }
  catch { if(Fs->except_ch=='Compiler') {Fs->catch_except=TRUE;rejected=TRUE;} }
  line=MStrPrint("OBS ESP REJECT %d %d\n",rejected,sink->count);
  EspReport(line);Free(line);Free(sink);EspReport("DONE ESP encoding\n");
}
EspContract;
