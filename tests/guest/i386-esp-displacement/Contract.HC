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
  CHashClass *value_type;
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
  for(i=0;i<9;i++) {
    sink->count=0;sink->measuring=FALSE;
    I386EbpAddress(sink,offsets[i]);count=sink->count;
    for(k=0;k<count;k++) {
      hex[2*k]=digits[buffer[k]>>4];hex[2*k+1]=digits[buffer[k]&15];
    }
    hex[2*count]=0;sink->count=0;sink->measuring=TRUE;
    I386EbpAddress(sink,offsets[i]);
    line=MStrPrint("OBS EBP %X %d %d %s\n",offsets[i],count,sink->count,hex);
    EspReport(line);Free(line);
  }
  for(i=0;i<9;i++)for(j=0;j<3;j++)for(register_index=0;register_index<8;register_index++) {
    sink->count=0;sink->measuring=FALSE;
    I386EbpMemory(sink,opcodes[j],register_index,offsets[i]);count=sink->count;
    for(k=0;k<count;k++) {
      hex[2*k]=digits[buffer[k]>>4];hex[2*k+1]=digits[buffer[k]&15];
    }
    hex[2*count]=0;sink->count=0;sink->measuring=TRUE;
    I386EbpMemory(sink,opcodes[j],register_index,offsets[i]);
    line=MStrPrint("OBS EBP MEM %X %d %X %d %d %s\n",opcodes[j],register_index,offsets[i],count,sink->count,hex);
    EspReport(line);Free(line);
  }
  for(i=0;i<9;i++)for(j=RT_I8;j<=RT_RTS_NUM;j++) {
    if(j<=RT_U64 || j==RT_F64 || j==RT_RTS_NUM) {
      if(j==RT_RTS_NUM)value_type=cmp.internal_types[RT_U8]+1;
      else value_type=cmp.internal_types[j];
      sink->count=0;sink->measuring=FALSE;
      I386LoadFrame(sink,value_type,offsets[i]);count=sink->count;
      for(k=0;k<count;k++) {
        hex[2*k]=digits[buffer[k]>>4];hex[2*k+1]=digits[buffer[k]&15];
      }
      hex[2*count]=0;sink->count=0;sink->measuring=TRUE;
      I386LoadFrame(sink,value_type,offsets[i]);
      line=MStrPrint("OBS FRAME LOAD %d %X %d %d %s\n",j,offsets[i],count,sink->count,hex);
      EspReport(line);Free(line);
    }
  }
  sink->count=0;sink->measuring=FALSE;
  try { I386EspMemory(sink,0x8B,8,0); }
  catch { if(Fs->except_ch=='Compiler') {Fs->catch_except=TRUE;rejected=TRUE;} }
  line=MStrPrint("OBS ESP REJECT %d %d\n",rejected,sink->count);
  EspReport(line);Free(line);
  rejected=FALSE;sink->count=0;
  try { I386EbpMemory(sink,0x8B,8,0); }
  catch { if(Fs->except_ch=='Compiler') {Fs->catch_except=TRUE;rejected=TRUE;} }
  line=MStrPrint("OBS EBP REJECT %d %d\n",rejected,sink->count);
  EspReport(line);Free(line);Free(sink);
}
EspContract;
